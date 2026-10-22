import '../../../../core/usecase/usecase.dart';
import '../../../covers/domain/entities/cover_key.dart';
import '../../../covers/domain/repositories/cover_repository.dart';
import '../entities/import_result.dart';
import '../entities/track.dart';
import '../entities/track_info.dart';
import '../repositories/library_repository.dart';

/// 보관함 곡 목록 (추가일 최신순, DB가 바뀌면 다시 흘려보냄).
class WatchLibraryTracks implements StreamUseCase<List<Track>, NoParams> {
  const WatchLibraryTracks(this._repo);

  final LibraryRepository _repo;

  @override
  Stream<List<Track>> call(NoParams _) => _repo.watchTracks();
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

/// 커버가 없는 기기 곡에 파일 내장 커버를 붙인다. 새로 붙인 수를 돌려준다.
/// 직접 고른 커버 · 웹 썸네일처럼 이미 커버가 있는 곡은 건드리지 않는다 (파일이 사라진 커버는 빈 것으로 본다).
/// 한 곡이 실패해도 나머지는 계속한다.
class FillEmbeddedCovers implements UseCase<int, NoParams> {
  const FillEmbeddedCovers(this._library, this._covers, this._embedded);

  final LibraryRepository _library;
  final CoverRepository _covers;
  final EmbeddedCoverRepository _embedded;

  @override
  Future<int> call(NoParams _) async {
    final tracks = await _library.watchTracks().first;
    final have = await _covers.loadAll();
    var filled = 0;
    for (final t in tracks) {
      if (t.source != TrackSource.device || t.uri.isEmpty) continue;
      final key = CoverKey.track(t.id);
      if (have.containsKey(key)) continue;
      String? temp;
      try {
        temp = await _embedded.extract(t);
        if (temp == null) continue;
        await _covers.save(key, temp);
        filled++;
      } on Exception {
        continue;
      } finally {
        if (temp != null) await _embedded.discard(temp);
      }
    }
    return filled;
  }
}

class UpdateTrackInfoParams {
  const UpdateTrackInfoParams(this.trackId, this.info);

  final String trackId;
  final TrackInfo info;
}

/// 곡 정보 편집 (곡 타일 메뉴). 제목은 앞뒤 공백을 지우고, 비어 있으면 바꾸지 않는다 (false).
class UpdateTrackInfo implements UseCase<bool, UpdateTrackInfoParams> {
  const UpdateTrackInfo(this._repo);

  final LibraryRepository _repo;

  @override
  Future<bool> call(UpdateTrackInfoParams p) {
    final info = p.info.trimmed();
    if (info.title.isEmpty) return Future.value(false);
    return _repo.updateInfo(p.trackId, info);
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
