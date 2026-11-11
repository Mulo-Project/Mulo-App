import 'dart:async';
import 'dart:io';

import '../../../../core/diagnostics/diag_notice.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../covers/domain/entities/cover_art.dart';
import '../../../covers/domain/entities/cover_key.dart';
import '../../../covers/domain/repositories/cover_repository.dart';
import '../entities/file_tags.dart';
import '../entities/import_result.dart';
import '../entities/loaded_folder.dart';
import '../entities/track.dart';
import '../entities/track_file_info.dart';
import '../entities/track_info.dart';
import '../repositories/library_repository.dart';
import '../repositories/track_tag_repository.dart';

/// 보관함 곡 목록 (추가일 최신순, DB나 불러오는 폴더가 바뀌면 다시 흘려보냄).
/// 불러오는 폴더 밖에 저장된 곡(받을 때 저장 위치를 따로 정한 경우)은 보관함에 보이지 않는다.
class WatchLibraryTracks implements StreamUseCase<List<Track>, NoParams> {
  const WatchLibraryTracks(this._repo, this._folders);

  final LibraryRepository _repo;
  final LoadedFolderRepository _folders;

  @override
  Stream<List<Track>> call(NoParams _) {
    late StreamController<List<Track>> out;
    final subs = <StreamSubscription<Object?>>[];
    List<Track>? latest;
    List<String>? roots;

    void emit() {
      final tracks = latest;
      final r = roots;
      if (tracks == null || r == null || out.isClosed) return;
      out.add([
        for (final t in tracks)
          if (isVisibleInLibrary(t, r)) t,
      ]);
    }

    Future<void> reloadRoots() async {
      roots = [
        _folders.defaultFolder,
        ..._folders.videoFolders,
        ...await _folders.loadExtra(),
      ];
      emit();
    }

    out = StreamController<List<Track>>(
      onListen: () {
        reloadRoots();
        subs
          ..add(
            _repo.watchTracks().listen((t) {
              latest = t;
              emit();
            }, onError: out.addError),
          )
          ..add(_folders.watchChanges().listen((_) => reloadRoots()));
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }
}

/// 불러오는 폴더 안의 음악을 찾아 보관함에 넣는다 (#11). 이미 있는 곡은 건너뛴다.
class ImportDeviceMusic implements UseCase<ImportOutcome, NoParams> {
  const ImportDeviceMusic(this._device, this._library, this._folders);

  final DeviceMusicRepository _device;
  final LibraryRepository _library;
  final LoadedFolderRepository _folders;

  @override
  Future<ImportOutcome> call(NoParams _) async {
    try {
      final folders = [_folders.defaultFolder, ...await _folders.loadExtra()];
      return switch (await _device.scan(folders)) {
        ScanCancelled() => const ImportCancelled(),
        ScanPermissionDenied() => const ImportDenied(),
        ScanFound(:final tracks) => ImportAdded(
          await _library.addTracks(tracks),
        ),
      };
    } on Exception {
      return const ImportFailed();
    }
  }
}

/// 커버가 없는 곡(기기에서 불러온 곡 · 앱에서 받은 곡)에 파일 내장 커버를 붙인다. 새로 붙인 수를 돌려준다.
/// 직접 고른 커버 · 웹 썸네일처럼 이미 커버가 있는 곡은 건드리지 않는다 (파일이 사라진 커버는 빈 것으로 본다).
/// 한 곡이 실패해도 나머지는 계속한다.
class FillEmbeddedCovers implements UseCase<int, NoParams> {
  const FillEmbeddedCovers(this._library, this._covers, this._embedded);

  final LibraryRepository _library;
  final CoverRepository _covers;
  final EmbeddedCoverRepository _embedded;

  @override
  Future<int> call(NoParams _) => run();

  /// 커버가 없거나, 웹 주소가 깨져(앞에 안 보이는 글자 등) 못 불러오는 곡은 파일 안 그림으로 채운다.
  static bool _needsCover(CoverArt? c) {
    if (c == null) return true;
    final path = c.path;
    if (path != null && path.isNotEmpty) return false;
    final url = c.url;
    return url != null && !url.startsWith('http');
  }

  /// [onProgress]로 (끝낸 곡 수, 채울 곡 수)를 알리며 채운다.
  Future<int> run({
    void Function(int done, int total)? onProgress,
    bool Function()? cancelled,
  }) async {
    final tracks = await _library.watchTracks().first;
    final have = await _covers.loadAll();
    final todo = [
      for (final t in tracks)
        if (t.uri.isNotEmpty && _needsCover(have[CoverKey.track(t.id)]))
          t,
    ];
    var filled = 0;
    final lines = <String>[];
    // 이미 커버 정보가 있어 채우지 않는 곡도 어떤 커버인지 적는다 (웹 주소 커버는 못 불러오면 빈 칸으로 보인다).
    for (final t in tracks) {
      final c = have[CoverKey.track(t.id)];
      if (c == null || t.uri.isEmpty) continue;
      final name = t.title.length > 14 ? t.title.substring(0, 14) : t.title;
      final url = c.url;
      final path = c.path;
      lines.add(
        '- $name: ${path != null && path.isNotEmpty ? 'file ${File(path).existsSync() ? 'ok' : 'MISSING'}' : 'url ${url == null ? 'none' : (url.length > 40 ? url.substring(0, 40) : url)}'}',
      );
    }
    _embedded.takeSummary();
    onProgress?.call(0, todo.length);
    for (final (i, t) in todo.indexed) {
      if (cancelled?.call() ?? false) break;
      final key = CoverKey.track(t.id);
      String? temp;
      try {
        temp = await _embedded.extract(t);
        final why = _embedded.takeSummary();
        final name = t.title.length > 14 ? t.title.substring(0, 14) : t.title;
        lines.add('${temp == null ? 'X' : 'O'} $name: $why');
        if (temp == null) continue;
        await _covers.save(key, temp);
        filled++;
      } on Exception {
        continue;
      } finally {
        if (temp != null) await _embedded.discard(temp);
        onProgress?.call(i + 1, todo.length);
      }
    }
    // 임시 진단: 디버그 빌드가 커버를 채운 결과를 snackbar로 보여 준다.
    if (todo.isNotEmpty) {
      DiagNotice.post(
        '[cover fill] ${todo.length}곡 중 $filled곡 채움\n${lines.join('\n')}',
      );
    }
    return filled;
  }
}

class UpdateTrackInfoParams {
  const UpdateTrackInfoParams(this.trackId, this.info);

  final String trackId;
  final TrackInfo info;
}

/// 곡 정보 편집 결과.
enum UpdateInfoResult {
  /// 저장했다.
  saved,

  /// 제목이 비었거나 없는 곡이라 바꾸지 않았다.
  invalid,

  /// 파일 태그에 쓰지 못해 DB도 바꾸지 않았다.
  tagWriteFailed,
}

/// 곡 정보 편집 (곡 타일 메뉴). 제목은 앞뒤 공백을 지우고, 비어 있으면 바꾸지 않는다.
///
/// 파일이 정보의 원본이고 DB는 캐시이므로 파일 태그에 먼저 쓰고, 성공해야 DB를 고친다.
/// 태그 쓰기가 실패하면 DB를 바꾸지 않는다 (DB에만 있는 편집이 이후 태그 복원 때 옛 값으로 되돌아가지 않게).
/// 태그를 쓰지 않는 곡([TagWriteResult.unsupported])과, 기기 곡의 쓰기 권한 없음([TagWriteResult.denied])은
/// 기존처럼 DB만 고친다.
class UpdateTrackInfo
    implements UseCase<UpdateInfoResult, UpdateTrackInfoParams> {
  const UpdateTrackInfo(this._repo, [this._tags]);

  final LibraryRepository _repo;
  final TrackTagRepository? _tags;

  @override
  Future<UpdateInfoResult> call(UpdateTrackInfoParams p) async {
    final info = p.info.trimmed();
    if (info.title.isEmpty) return UpdateInfoResult.invalid;
    final tags = _tags;
    if (tags != null) {
      final tracks = await _repo.watchTracks().first;
      final track = tracks.where((t) => t.id == p.trackId).firstOrNull;
      if (track == null) return UpdateInfoResult.invalid;
      TagWriteResult result;
      try {
        result = await tags.write(track.withInfo(info));
      } on Object {
        result = TagWriteResult.failed;
      }
      final blocks =
          result == TagWriteResult.failed ||
          (result == TagWriteResult.denied &&
              track.source == TrackSource.download);
      if (blocks) return UpdateInfoResult.tagWriteFailed;
    }
    return await _repo.updateInfo(p.trackId, info)
        ? UpdateInfoResult.saved
        : UpdateInfoResult.invalid;
  }
}

/// 받아 둔 곡의 파일 태그에 정보를 한꺼번에 쓴다 (기존 파일 이관). 앱이 뜬 뒤 뒤에서 돈다.
/// 곡마다 끝낸 id를 기록해 중간에 꺼져도 이어서 하고, 쓸 수 없는 파일은 다시 시도하지 않는다.
/// 이번에 태그를 쓴 곡 수를 돌려준다.
class EmbedTagsIntoFiles implements UseCase<int, NoParams> {
  const EmbedTagsIntoFiles(
    this._library,
    this._covers,
    this._colors,
    this._tags,
    this._done,
  );

  final LibraryRepository _library;
  final CoverRepository _covers;
  final CoverColorRepository _colors;
  final TrackTagRepository _tags;
  final TagMigrationStore _done;

  @override
  Future<int> call(NoParams _) async {
    final tracks = await _library.watchTracks().first;
    final done = await _done.loadDone();
    final covers = await _covers.loadAll();
    final colors = await _colors.loadAll();
    var written = 0;
    for (final t in tracks) {
      if (t.source != TrackSource.download || t.uri.isEmpty) continue;
      if (done.contains(t.id)) continue;
      try {
        final key = CoverKey.track(t.id);
        if (await _tags.write(t, cover: covers[key], color: colors[key]) ==
            TagWriteResult.written) {
          written++;
        }
      } on Exception {
        // 한 곡이 실패해도 나머지는 계속한다.
      }
      await _done.markDone([t.id]);
    }
    return written;
  }
}

/// 파일 태그를 읽어 앱 DB를 다시 채운다 (파일이 원본, DB는 캐시). 앱 밖에서 옮겨 와 새로 찾은 기기 곡이나
/// DB가 비었을 때 곡 정보가 돌아오게 한다: 제목 · 아티스트 · 앨범 · 장르, 그리고 커버 편집 상태
/// (`COVER_SOURCE` · `COVER_TRANSFORM` · `COVER_COLOR`). 가사는 보여 줄 때 태그에서 바로 읽으므로 옮기지 않고,
/// 태그에 이미지만 있는 커버는 [FillEmbeddedCovers]가 이어서 채운다.
/// 곡마다 한 번만 하고(기록), 앱 안에서 이미 정한 커버 · 색은 덮지 않는다. 못 읽은 곡은 다음에 다시 시도한다.
/// 복원한 곡 수를 돌려준다.
class RestoreFromFileTags implements UseCase<int, NoParams> {
  const RestoreFromFileTags(
    this._library,
    this._covers,
    this._colors,
    this._tags,
    this._done,
  );

  final LibraryRepository _library;
  final CoverRepository _covers;
  final CoverColorRepository _colors;
  final FileTagRepository _tags;
  final TagRestoreStore _done;

  @override
  Future<int> call(NoParams _) => run();

  /// [onProgress]로 (끝낸 곡 수, 읽을 곡 수)를 알리며 되살린다.
  Future<int> run({
    void Function(int done, int total)? onProgress,
    bool Function()? cancelled,
  }) async {
    final tracks = await _library.watchTracks().first;
    final done = await _done.loadDone();
    final covers = await _covers.loadAll();
    final colors = await _colors.loadAll();
    final todo = [
      for (final t in tracks)
        if (t.source == TrackSource.device &&
            t.uri.isNotEmpty &&
            !done.contains(t.id))
          t,
    ];
    var restored = 0;
    onProgress?.call(0, todo.length);
    for (final (i, t) in todo.indexed) {
      if (cancelled?.call() ?? false) break;
      try {
        final tags = await _tags.read(t);
        if (tags == null) continue;
        if (!tags.isEmpty) {
          await _apply(t, tags, covers, colors);
          restored++;
        }
        await _done.markDone([t.id]);
      } on Exception {
        // 한 곡이 실패해도 나머지는 계속한다 (기록하지 않아 다음에 다시 시도).
      }
      onProgress?.call(i + 1, todo.length);
    }
    // 임시 진단: 읽은 결과를 디버그 빌드가 snackbar로 보여 준다.
    final summary = _tags.takeSummary();
    if (todo.isNotEmpty) {
      DiagNotice.post('[tag read] ${todo.length}곡 · 반영 $restored · $summary');
    }
    return restored;
  }

  Future<void> _apply(
    Track t,
    FileTags tags,
    Map<String, CoverArt> covers,
    Map<String, int> colors,
  ) async {
    String pick(String fromFile, String current) =>
        fromFile.trim().isEmpty ? current : fromFile.trim();
    await _library.updateInfo(
      t.id,
      TrackInfo(
        title: pick(tags.title, t.title),
        artist: pick(tags.artist, t.artist),
        album: pick(tags.album, t.album),
        genre: pick(tags.genre, t.genre),
      ),
    );
    final key = CoverKey.track(t.id);
    final source = tags.coverSource;
    if (source != null && !covers.containsKey(key)) {
      await _covers.saveUrl(key, source, transform: tags.coverTransform);
    }
    final color = tags.coverColor;
    if (color != null && !colors.containsKey(key)) {
      await _colors.save(key, color);
    }
  }
}

/// 곡을 지운다: 음악 파일을 지우고, 보관함 · 재생목록 · 기록에서도 뺀다.
/// 파일을 못 지우면 아무것도 바꾸지 않고 false.
class DeleteTrack implements UseCase<bool, Track> {
  const DeleteTrack(this._library, this._files);

  final LibraryRepository _library;
  final TrackFileRepository _files;

  @override
  Future<bool> call(Track track) async {
    if (!await _files.deleteFile(track)) return false;
    await _library.delete(track.id);
    return true;
  }
}

/// 곡의 음악 파일 정보 (크기 · 형식 · 비트레이트 · 샘플레이트). 읽을 수 없으면 null.
class GetTrackFileInfo implements UseCase<TrackFileInfo?, Track> {
  const GetTrackFileInfo(this._files);

  final TrackFileRepository _files;

  @override
  Future<TrackFileInfo?> call(Track track) => _files.fileInfo(track);
}
