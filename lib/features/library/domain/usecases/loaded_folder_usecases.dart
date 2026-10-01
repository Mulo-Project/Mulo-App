import '../../../../core/usecase/usecase.dart';
import '../entities/loaded_folder.dart';
import '../repositories/library_repository.dart';

/// 불러오는 폴더 목록과 폴더별 곡 수 (기본 저장 위치가 맨 위).
class LoadLoadedFolders implements UseCase<List<LoadedFolder>, NoParams> {
  const LoadLoadedFolders(this._folders, this._library);

  final LoadedFolderRepository _folders;
  final LibraryRepository _library;

  @override
  Future<List<LoadedFolder>> call(NoParams _) async {
    final tracks = await _library.watchTracks().first;
    final extra = await _folders.loadExtra();
    return [
      LoadedFolder(
        path: _folders.defaultFolder,
        trackCount: countTracksIn(_folders.defaultFolder, tracks),
        isDefault: true,
      ),
      for (final path in extra)
        LoadedFolder(path: path, trackCount: countTracksIn(path, tracks)),
    ];
  }
}

enum AddFolderResult { added, cancelled, duplicate }

/// 폴더를 골라 목록에 더한다. 이미 있으면(기본 저장 위치 포함) 더하지 않는다.
class AddLoadedFolder implements UseCase<AddFolderResult, NoParams> {
  const AddLoadedFolder(this._folders);

  final LoadedFolderRepository _folders;

  @override
  Future<AddFolderResult> call(NoParams _) async {
    final picked = await _folders.pickFolder();
    if (picked == null || picked.trim().isEmpty) {
      return AddFolderResult.cancelled;
    }
    final path = normalizeFolderPath(picked);
    final extra = await _folders.loadExtra();
    final known = [_folders.defaultFolder, ...extra].map(normalizeFolderPath);
    if (known.contains(path)) return AddFolderResult.duplicate;
    await _folders.saveExtra([...extra, path]);
    return AddFolderResult.added;
  }
}

/// 폴더를 목록에서 뺀다. 기본 저장 위치는 뺄 수 없다.
class RemoveLoadedFolder implements UseCase<bool, String> {
  const RemoveLoadedFolder(this._folders);

  final LoadedFolderRepository _folders;

  @override
  Future<bool> call(String path) async {
    final target = normalizeFolderPath(path);
    if (target == normalizeFolderPath(_folders.defaultFolder)) return false;
    final extra = await _folders.loadExtra();
    final kept = [
      for (final p in extra)
        if (normalizeFolderPath(p) != target) p,
    ];
    if (kept.length == extra.length) return false;
    await _folders.saveExtra(kept);
    return true;
  }
}
