import '../../../../core/usecase/usecase.dart';
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
