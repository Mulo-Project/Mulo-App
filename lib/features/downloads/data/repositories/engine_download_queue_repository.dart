import 'dart:async';
import 'dart:io';

import '../../../covers/domain/entities/cover_key.dart';
import '../../../covers/domain/repositories/cover_repository.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../../playlists/domain/repositories/playlist_repository.dart';
import '../../../search/domain/entities/engine_exception.dart';
import '../../../search/domain/repositories/downloader_engine.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/repositories/download_queue_repository.dart';
import '../../domain/repositories/download_settings_repository.dart';
import '../datasources/audio_file_downloader.dart';
import '../datasources/downloaded_file_store.dart';

/// 대기열을 실제로 받는 저장소: 한 곡씩 차례로
/// 엔진으로 오디오 스트림 주소를 읽고 → 구간 요청으로 임시 파일에 받고 → 음악 폴더에 저장한 뒤
/// 보관함에 곡을 만들고 커버 · 색 · 재생목록을 붙인다.
///
/// 저장 형식은 스트림이 주는 원본 그대로다(Android는 webm/opus). 변환은 하지 않는다.
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
    required this._tempDir,
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
  final Future<Directory> Function() _tempDir;
  final DateTime Function() _now;

  final _items = <DownloadItem>[];
  final _requests = <String, DownloadRequest>{};
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
      onListen: () {
        out.add([..._items]);
        sub = _changes.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    // 끝난 곡은 새로 받기 시작할 때 목록에서 치운다.
    _items.removeWhere((e) => e.status == DownloadStatus.done);
    final id = 'd${_now().microsecondsSinceEpoch}_${_seq++}';
    _requests[id] = request;
    _items.add(
      DownloadItem(
        id: id,
        title: request.title,
        artist: request.artist,
        genre: request.genre,
        color: request.color,
        thumbnailUrl: request.thumbnailUrl,
        playlistIds: request.playlistIds,
        status: DownloadStatus.queued,
        duration: request.duration,
        url: request.url,
      ),
    );
    _emit();
    unawaited(_pump());
  }

  @override
  Future<void> pause(String id) async {
    final item = _find(id);
    if (item == null ||
        !item.isActive ||
        item.status == DownloadStatus.paused) {
      return;
    }
    if (_runningId == id) _token?.cancel();
    _set(id, (e) => e.copyWith(status: DownloadStatus.paused, progress: 0));
  }

  @override
  Future<void> resume(String id) async {
    if (_find(id)?.status != DownloadStatus.paused) return;
    _moveToEnd(id);
    _set(id, (e) => e.copyWith(status: DownloadStatus.queued));
    unawaited(_pump());
  }

  @override
  Future<void> retry(String id) async {
    if (_find(id)?.status != DownloadStatus.failed) return;
    _moveToEnd(id);
    _set(
      id,
      (e) => e.copyWith(status: DownloadStatus.queued, progress: 0, error: ''),
    );
    unawaited(_pump());
  }

  @override
  Future<void> cancel(String id) async {
    if (_runningId == id) _token?.cancel();
    _items.removeWhere((e) => e.id == id);
    _requests.remove(id);
    _emit();
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

  void _set(String id, DownloadItem Function(DownloadItem) change) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = change(_items[i]);
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add([..._items]);
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
    _set(
      id,
      (e) => e.copyWith(status: DownloadStatus.downloading, progress: 0),
    );

    File? temp;
    try {
      final stream = await _engine.resolveAudioStream(request.url);
      if (token.isCancelled) throw const DownloadAborted();
      final dir = await _tempDir();
      temp = File('${dir.path}${Platform.pathSeparator}$id.part');
      var lastShown = 0.0;
      final audio = await _downloader.download(
        stream,
        temp,
        token: token,
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
          );
        },
      );
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
      await _register(id, request, saved);
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
      if (temp != null) await _deleteQuietly(temp);
      _runningId = null;
      _token = null;
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
  ) async {
    final trackId = 'download:$id';
    await _library.addTracks([
      Track(
        id: trackId,
        title: request.title,
        artist: request.artist,
        album: '',
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
