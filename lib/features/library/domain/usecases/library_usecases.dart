import '../../../../core/usecase/usecase.dart';
import '../entities/import_result.dart';
import '../entities/track.dart';
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
