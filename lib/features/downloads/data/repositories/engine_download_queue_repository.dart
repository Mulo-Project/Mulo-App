import 'dart:async';
import 'dart:io';

import '../../../covers/domain/entities/cover_key.dart';
import '../../../covers/domain/repositories/cover_repository.dart';
import '../../../library/domain/entities/track.dart';
import '../../../lyrics/domain/repositories/lyrics_repository.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../../playlists/domain/repositories/playlist_repository.dart';
import '../../../search/domain/entities/engine_exception.dart';
import '../../../search/domain/repositories/downloader_engine.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/entities/download_source.dart';
import '../../domain/entities/tag_notice.dart';
import '../../domain/repositories/download_queue_repository.dart';
import '../../domain/repositories/download_settings_repository.dart';
import '../datasources/audio_file_downloader.dart';
import '../datasources/audio_transcoder.dart';
import '../datasources/cover_tag_writer.dart';
import '../datasources/ffmpeg_tag_writer.dart';
import '../datasources/download_queue_store.dart';
import '../datasources/downloaded_file_store.dart';

/// 대기열을 실제로 받는 저장소: 한 곡씩 차례로
/// 엔진으로 오디오 스트림 주소를 읽고 → 구간 요청으로 임시 파일에 받고 → 음악 폴더에 저장한 뒤
/// 보관함에 곡을 만들고 커버 · 색 · 재생목록을 붙인다.
///
/// - 저장 형식은 기본적으로 스트림 원본이고(Android는 webm/opus), 설정의 형식이 mp3면 받은 뒤 [AudioTranscoder]로 바꾼다. 변환기가 없거나 실패하면 원본을 그대로 저장한다.
/// - 일시정지 · 실패해도 받은 만큼은 임시 폴더에 남기고, 다시 받을 때 HTTP 구간 요청으로 이어 받는다.
/// - 대기열은 [DownloadQueueStore]에 저장되어 앱을 다시 켜도 이어서 받는다 (받는 중이던 곡은 대기로 돌아온다).
class EngineDownloadQueueRepository implements DownloadQueueRepository {
  EngineDownloadQueueRepository({
    required this._engine,
    required this._downloader,
    required this._store,
    required this._library,
    required this._playlists,
    required this._covers,
    required this._colors,
    required this._settings,
    required this._transcoder,
    required this._queueStore,
    required this._tempDir,
    this._coverTags,
    this._lyrics,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DownloaderEngine _engine;
  final AudioFileDownloader _downloader;
  final DownloadedFileStore _store;
  final LibraryRepository _library;
  final PlaylistRepository _playlists;
  final CoverRepository _covers;
  final CoverColorRepository _colors;
  final DownloadSettingsRepository _settings;
  final AudioTranscoder _transcoder;
  final CoverTagWriter? _coverTags;
  final LyricsRepository? _lyrics;
  final DownloadQueueStore _queueStore;
  final Future<Directory> Function() _tempDir;
  final DateTime Function() _now;

  final _items = <DownloadItem>[];
  final _requests = <String, DownloadRequest>{};

  /// 받다 만 임시 파일의 형식 (이어받을 때 같은 형식의 주소인지 확인한다).
  final _partMime = <String, String>{};

  /// 원본 주소 키 → 받아서 만든 곡 id (이미 받은 곡 찾기).
  var _sources = <String, String>{};
  Future<void>? _loaded;
  Future<void> _saving = Future.value();
  final _changes = StreamController<List<DownloadItem>>.broadcast();
  var _seq = 0;

  /// 받는 중인 항목과 그 멈춤 표시 (한 번에 한 곡).
  String? _runningId;
  DownloadCancelToken? _token;
  bool _pumping = false;

  /// 진행률은 이만큼 이상 바뀔 때만 흘려보낸다 (화면을 너무 자주 그리지 않도록).
  static const _progressStep = 0.01;

  @override
  Stream<List<DownloadItem>> watchQueue() {
    // 지금 목록을 먼저 주고 바로 변경을 이어 듣는다 (그 사이 바뀐 것을 놓치지 않도록).
    late final StreamController<List<DownloadItem>> out;
    StreamSubscription<List<DownloadItem>>? sub;
    out = StreamController<List<DownloadItem>>(
      onListen: () async {
        await _ensureLoaded();
        out.add([..._items]);
        sub = _changes.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  /// 저장해 둔 대기열을 처음 한 번 불러와 받던 것을 이어 간다.
  Future<void> _ensureLoaded() => _loaded ??= _load();

  Future<void> _load() async {
    _sources = await _queueStore.loadSources();
    for (final s in await _queueStore.loadQueue()) {
      if (s.status == DownloadStatus.done) continue;
      _requests[s.id] = s.request;
      if (s.partMime != null) _partMime[s.id] = s.partMime!;
      _items.add(
        _itemFor(
          s.id,
          s.request,
          // 앱이 꺼질 때 받던 곡은 대기로 돌아와 이어서 받는다.
          s.status == DownloadStatus.downloading
              ? DownloadStatus.queued
              : s.status,
          progress: s.progress,
          error: s.error,
        ),
      );
    }
    if (_items.isNotEmpty) _emit(persist: false);
    unawaited(_pump());
  }

  DownloadItem _itemFor(
    String id,
    DownloadRequest request,
    DownloadStatus status, {
    double progress = 0,
    String error = '',
  }) => DownloadItem(
    id: id,
    title: request.title,
    artist: request.artist,
    genre: request.genre,
    color: request.color,
    thumbnailUrl: request.thumbnailUrl,
    cover: request.cover,
    playlistIds: request.playlistIds,
    status: status,
    progress: progress,
    duration: request.duration,
    url: request.url,
    error: error,
  );

  @override
  Future<ExistingDownload> findExisting(String url) async {
    await _ensureLoaded();
    final key = downloadSourceKey(url);
    final inQueue = _items.any(
      (e) => e.isActive && downloadSourceKey(e.url) == key,
    );
    final trackId = _sources[key];
    var exists = false;
    if (trackId != null) {
      exists = (await _library.watchTracks().first).any((t) => t.id == trackId);
    }
    return ExistingDownload(trackId: exists ? trackId : null, inQueue: inQueue);
  }

  @override
  Future<String?> sourceUrlOf(String trackId) async {
    await _ensureLoaded();
    for (final e in _sources.entries) {
      if (e.value != trackId) continue;
      const prefix = 'youtube:';
      return e.key.startsWith(prefix)
          ? 'https://www.youtube.com/watch?v=${e.key.substring(prefix.length)}'
          : e.key;
    }
    return null;
  }

  final _tagNotices = StreamController<TagNotice>.broadcast();

  @override
  Stream<TagNotice> watchTagNotices() => _tagNotices.stream;

  /// 받은 곡 키가 바뀌었음을 알린다 (곡을 만든 직후 · 원본 주소 기록 뒤).
  final _keysChanged = StreamController<void>.broadcast();

  @override
  Stream<Set<String>> watchDownloadedKeys() {
    late final StreamController<Set<String>> out;
    StreamSubscription<Object?>? libSub;
    StreamSubscription<void>? keySub;
    var ids = <String>{};
    void emit() {
      if (out.isClosed) return;
      out.add({
        for (final e in _sources.entries)
          if (ids.contains(e.value)) e.key,
      });
    }

    out = StreamController<Set<String>>(
      onListen: () async {
        await _ensureLoaded();
        libSub = _library.watchTracks().listen((tracks) {
          ids = {for (final t in tracks) t.id};
          emit();
        });
        keySub = _keysChanged.stream.listen((_) => emit());
      },
      onCancel: () async {
        await libSub?.cancel();
        await keySub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    await _ensureLoaded();
    // 끝난 곡은 새로 받기 시작할 때 목록에서 치운다.
    _items.removeWhere((e) => e.status == DownloadStatus.done);
    final id = 'd${_now().microsecondsSinceEpoch}_${_seq++}';
    _requests[id] = request;
    _items.add(_itemFor(id, request, DownloadStatus.queued));
    _emit();
    unawaited(_pump());
  }

  @override
  Future<void> pause(String id) async {
    await _ensureLoaded();
    final item = _find(id);
    if (item == null ||
        !item.isActive ||
        item.status == DownloadStatus.paused) {
      return;
    }
    if (_runningId == id) {
      _token?.cancel();
      unawaited(_transcoder.cancel());
    }
    // 받은 만큼은 임시 파일에 남아 있어 다시 받을 때 이어 받는다.
    _set(id, (e) => e.copyWith(status: DownloadStatus.paused));
  }

  @override
  Future<void> resume(String id) async {
    await _ensureLoaded();
    if (_find(id)?.status != DownloadStatus.paused) return;
    _moveToEnd(id);
    _set(id, (e) => e.copyWith(status: DownloadStatus.queued));
    unawaited(_pump());
  }

  @override
  Future<void> retry(String id) async {
    await _ensureLoaded();
    if (_find(id)?.status != DownloadStatus.failed) return;
    _moveToEnd(id);
    // 실패 전에 받아 둔 만큼이 있으면 이어 받는다.
    _set(id, (e) => e.copyWith(status: DownloadStatus.queued, error: ''));
    unawaited(_pump());
  }

  @override
  Future<void> cancel(String id) async {
    await _ensureLoaded();
    if (_runningId == id) {
      _token?.cancel();
      unawaited(_transcoder.cancel());
    }
    _items.removeWhere((e) => e.id == id);
    _requests.remove(id);
    _partMime.remove(id);
    // 받던 중이면 멈춘 뒤 _run이 임시 파일을 지운다. 받고 있지 않으면 여기서 지운다.
    if (_runningId != id) unawaited(_deletePart(id));
    _emit();
  }

  @override
  Future<int> cancelAll({String? playlistId}) async {
    await _ensureLoaded();
    final ids = [
      for (final e in _items)
        if (e.status != DownloadStatus.done &&
            (playlistId == null || e.playlistIds.contains(playlistId)))
          e.id,
    ];
    for (final id in ids) {
      await cancel(id);
    }
    return ids.length;
  }

  DownloadItem? _find(String id) {
    for (final e in _items) {
      if (e.id == id) return e;
    }
    return null;
  }

  void _moveToEnd(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items.add(_items.removeAt(i));
  }

  /// [persist]가 true면 대기열을 저장한다 (진행률만 바뀔 때는 저장하지 않는다).
  void _set(
    String id,
    DownloadItem Function(DownloadItem) change, {
    bool persist = true,
  }) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = change(_items[i]);
    _emit(persist: persist);
  }

  void _emit({bool persist = true}) {
    if (!_changes.isClosed) _changes.add([..._items]);
    if (persist) _persist();
  }

  /// 끝난 곡을 뺀 대기열을 저장한다 (쓰기는 차례대로).
  void _persist() {
    final snapshot = [
      for (final e in _items)
        if (e.status != DownloadStatus.done && _requests[e.id] != null)
          StoredDownload(
            id: e.id,
            request: _requests[e.id]!,
            status: e.status,
            progress: e.progress,
            error: e.error,
            partMime: _partMime[e.id],
          ),
    ];
    _saving = _saving
        .then((_) => _queueStore.saveQueue(snapshot))
        .catchError((Object _) {});
  }

  /// 대기 중인 첫 곡부터 하나씩 받는다. 이미 돌고 있으면 그 반복이 이어서 가져간다.
  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        final next = _items
            .where((e) => e.status == DownloadStatus.queued)
            .firstOrNull;
        if (next == null) break;
        await _run(next);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(DownloadItem item) async {
    final id = item.id;
    final request = _requests[id];
    if (request == null) {
      _items.removeWhere((e) => e.id == id);
      _emit();
      return;
    }
    final token = DownloadCancelToken();
    _token = token;
    _runningId = id;
    // 이어 받는 곡은 받아 둔 진행률을 그대로 보여 준다.
    _set(id, (e) => e.copyWith(status: DownloadStatus.downloading));

    File? temp;
    File? converted;
    try {
      final format = request.format ?? await _settings.loadFormat();
      final dir = await _tempDir();
      await dir.create(recursive: true);
      temp = File(_partPath(dir, id));
      var lastShown = 0.0;
      Future<DownloadedAudio> fetch({required bool refresh}) async {
        final stream = await _engine.resolveAudioStream(
          request.url,
          refresh: refresh,
          audioLanguage: request.audioLanguage,
        );
        if (token.isCancelled) throw const DownloadAborted();
        return _downloader.download(
          stream,
          temp!,
          token: token,
          resumeMime: refresh ? null : _partMime[id],
          onMime: (mime) {
            _partMime[id] = mime;
            _persist();
          },
          onProgress: (p) {
            if (token.isCancelled || (p - lastShown < _progressStep && p < 1)) {
              return;
            }
            lastShown = p;
            _set(
              id,
              (e) => e.status == DownloadStatus.downloading
                  ? e.copyWith(progress: p)
                  : e,
              persist: false,
            );
          },
        );
      }

      DownloadedAudio audio;
      try {
        audio = await fetch(refresh: false);
      } on DownloadFailed {
        // 주소가 막혔거나(403) 만료됐을 수 있다: 기억해 둔 주소를 버리고 새로 읽어 처음부터 한 번 더 받는다.
        if (token.isCancelled) throw const DownloadAborted();
        lastShown = 0;
        audio = await fetch(refresh: true);
      }
      if (token.isCancelled) throw const DownloadAborted();
      // 내려받기는 끝났다: 이제 변환 · 태그 쓰기 · 저장이라 "처리 중"으로 보인다.
      _set(
        id,
        (e) => e.status == DownloadStatus.downloading
            ? e.copyWith(progress: 1, processing: true)
            : e,
        persist: false,
      );

      // 설정의 형식대로 바꾼다. 변환기가 없거나 실패하면 받은 그대로 저장한다.
      final plan = TranscodePlan.of(format);
      if (plan != null) {
        converted = File('${dir.path}${Platform.pathSeparator}$id.conv');
        final result = await _transcoder.convert(audio, plan, converted);
        if (token.isCancelled) throw const DownloadAborted();
        if (result != null) audio = result;
      }

      // 가사(고친 글 또는 영상 자막)를 먼저 구해 파일 태그와 앱 가사에 같은 글을 쓴다.
      final lyrics = await _lyricsFor(request);
      if (token.isCancelled) throw const DownloadAborted();

      // 고른 커버(없으면 썸네일)를 파일 태그에도 넣는다. 쓸 수 없는 형식이면 그대로 저장한다.
      final tagged = await _coverTags?.embed(
        audio.file,
        extension: audio.extension,
        cover: request.cover,
        thumbnailUrl: request.thumbnailUrl,
        title: request.title,
        artist: request.artist,
        album: request.album,
        genre: request.genre,
        lyrics: lyrics,
        color: request.color,
      );
      // 태그를 못 썼으면 화면이 알린다 (임시: 쓴 결과도 진단용으로 함께 보낸다).
      if (_coverTags != null && tagged != null) {
        _tagNotices.add(
          TagNotice(
            title: request.title,
            extension: audio.extension,
            ok: tagged,
            detail: tagged
                ? ''
                : (FfmpegTagWriter.lastError ?? 'unsupported or nothing to write'),
          ),
        );
      }
      if (token.isCancelled) throw const DownloadAborted();

      final folder = request.savePath.isNotEmpty
          ? request.savePath
          : await _settings.loadSavePath();
      final saved = await _store.save(
        audio.file,
        folder: folder,
        name: _fileName(request),
        extension: audio.extension,
        mime: audio.mime,
        title: request.title,
        artist: request.artist,
      );
      await _register(id, request, saved, lyrics);
      // 고정한 폴더가 없을 때의 기준: 마지막에 받은 폴더.
      await _settings.saveLastSavePath(folder);
      _set(id, (e) => e.copyWith(status: DownloadStatus.done, progress: 1));
    } on DownloadAborted {
      // 취소(목록에서 이미 뺐다) 또는 일시정지(상태를 이미 바꿨다)다.
    } on EngineException catch (e) {
      _fail(id, _engineMessage(e));
    } on DownloadFailed catch (e) {
      _fail(id, e.message);
    } on Object catch (e) {
      _fail(id, '$e');
    } finally {
      // 멈춘 곡 · 실패한 곡은 받은 만큼을 남겨 두고 다음에 이어 받는다. 그 밖에는 지운다.
      final keep = switch (_find(id)?.status) {
        DownloadStatus.paused || DownloadStatus.failed => true,
        _ => false,
      };
      if (temp != null && !keep) await _deleteQuietly(temp);
      if (!keep) _partMime.remove(id);
      if (converted != null) await _deleteQuietly(converted);
      _runningId = null;
      _token = null;
    }
  }

  static String _partPath(Directory dir, String id) =>
      '${dir.path}${Platform.pathSeparator}$id.part';

  Future<void> _deletePart(String id) async {
    try {
      await _deleteQuietly(File(_partPath(await _tempDir(), id)));
    } on Object {
      // 임시 폴더를 못 열면 지울 것도 없다.
    }
  }

  void _fail(String id, String message) => _set(
    id,
    (e) => e.copyWith(status: DownloadStatus.failed, error: _oneLine(message)),
  );

  /// 보관함에 곡을 만들고 재생목록 · 커버 · 색을 붙인다.
  Future<void> _register(
    String id,
    DownloadRequest request,
    SavedAudio saved,
    String? lyrics,
  ) async {
    final trackId = 'download:$id';
    await _library.addTracks([
      Track(
        id: trackId,
        title: request.title,
        artist: request.artist,
        album: request.album,
        genre: request.genre,
        duration: request.duration ?? Duration.zero,
        addedAt: _now(),
        uri: saved.uri,
        folder: saved.folder,
        source: TrackSource.download,
      ),
    ]);
    if (request.playlistIds.isNotEmpty) {
      await _playlists.addTrack(trackId, request.playlistIds);
    }
    final key = CoverKey.track(trackId);
    final art = request.cover;
    final thumb = request.thumbnailUrl;
    if (art != null) {
      if (art.url case final url?) {
        await _covers.saveUrl(key, url, transform: art.transform);
      } else if (art.path case final path?) {
        await _covers.save(key, path, transform: art.transform);
      }
    } else if (thumb != null && thumb.isNotEmpty) {
      await _covers.saveUrl(key, thumb);
    }
    final color = request.color;
    if (color != null) await _colors.save(CoverKey.track(trackId), color);
    // 같은 원본 주소를 다시 받지 않도록 기억한다 (재생목록 가져오기가 건너뛴다).
    _sources[downloadSourceKey(request.url)] = trackId;
    _keysChanged.add(null);
    await _queueStore.saveSources(_sources);
    if (lyrics != null) {
      try {
        await _lyrics?.save(trackId, lyrics);
      } on Object {
        // 가사는 덤이라 실패해도 받은 곡은 그대로 둔다.
      }
    }
  }

  /// 받은 곡에 넣을 가사 글. 받기 전에 고쳐 둔 글이 있으면 그대로, 아니면 영상 자막을 싱크 가사(.lrc)로 바꾼다.
  /// 자막이 없거나 읽지 못해도 받기는 성공으로 둔다 (null). 파일 태그와 앱 가사가 같은 글을 쓰도록 먼저 구한다.
  Future<String?> _lyricsFor(DownloadRequest request) async {
    if (!request.importLyrics || _lyrics == null) return null;
    final text = request.lyricsText;
    if (text != null && text.trim().isNotEmpty) return text;
    try {
      final track = await _engine.fetchSubtitles(
        request.url,
        preferLanguages: request.lyricsLanguage == null
            ? const ['ko', 'en']
            : [request.lyricsLanguage!],
      );
      final lrc =
          (request.lyricsSkipSounds ? track?.withoutSoundCues() : track)
              ?.toLrc() ??
          '';
      return lrc.isEmpty ? null : lrc;
    } on Object {
      // 자막은 덤이라 실패해도 받은 곡은 그대로 둔다.
      return null;
    }
  }

  static String _fileName(DownloadRequest r) {
    final raw = r.artist.isEmpty ? r.title : '${r.artist} - ${r.title}';
    final clean = raw
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cut = clean.length > 120 ? clean.substring(0, 120).trim() : clean;
    return cut.isEmpty ? 'download' : cut;
  }

  static String _engineMessage(EngineException e) => switch (e.failure) {
    EngineFailure.unavailable => '받을 수 있는 엔진이 없어요',
    EngineFailure.network => '네트워크에 닿지 못했어요',
    EngineFailure.timeout => '응답이 너무 오래 걸려요',
    EngineFailure.unauthorized => '서버가 로그인을 요구해요',
    EngineFailure.notFound => '찾을 수 없는 주소예요',
    EngineFailure.failed => e.message.isEmpty ? '주소를 읽지 못했어요' : e.message,
  };

  static String _oneLine(String s) =>
      s.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).join(' / ');

  static Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on Object {
      // 임시 파일이라 못 지워도 괜찮다.
    }
  }
}
