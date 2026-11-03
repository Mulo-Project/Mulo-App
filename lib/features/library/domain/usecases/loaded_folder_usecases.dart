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
    // 불러오는 폴더를 더하면 저장 위치 목록에도 더한다 (그 뒤로는 서로 따로 움직인다).
    await _addSaveLocation(_folders, path);
    return AddFolderResult.added;
  }
}

/// 저장 위치 목록 (기본 저장 위치 제외). 따로 저장한 적이 없으면 불러오는 폴더를 처음 목록으로 쓴다.
Future<List<String>> _storedSaveLocations(
  LoadedFolderRepository folders,
) async => (await folders.loadSaveLocations()) ?? await folders.loadExtra();

Future<void> _addSaveLocation(
  LoadedFolderRepository folders,
  String path,
) async {
  final target = normalizeFolderPath(path);
  if (target.isEmpty || target == normalizeFolderPath(folders.defaultFolder)) {
    return;
  }
  final list = await _storedSaveLocations(folders);
  if (list.any((p) => normalizeFolderPath(p) == target)) {
    await folders.saveSaveLocations(list);
    return;
  }
  await folders.saveSaveLocations([...list, target]);
}

/// 저장 위치 목록: 기본 저장 위치가 맨 위. 불러오는 폴더와는 따로 관리된다.
class LoadSaveLocations implements UseCase<List<String>, NoParams> {
  const LoadSaveLocations(this._folders);

  final LoadedFolderRepository _folders;

  @override
  Future<List<String>> call(NoParams _) async => [
    _folders.defaultFolder,
    ...await _storedSaveLocations(_folders),
  ];
}

/// 저장 위치를 목록에 더한다 (이미 있거나 기본 저장 위치면 그대로).
class AddSaveLocation implements UseCase<void, String> {
  const AddSaveLocation(this._folders);

  final LoadedFolderRepository _folders;

  @override
  Future<void> call(String path) => _addSaveLocation(_folders, path);
}

/// 저장 위치를 목록에서 뺀다. 불러오는 폴더 목록과 보관함의 곡은 그대로다. 기본 저장 위치는 뺄 수 없다.
class RemoveSaveLocation implements UseCase<void, String> {
  const RemoveSaveLocation(this._folders);

  final LoadedFolderRepository _folders;

  @override
  Future<void> call(String path) async {
    final target = normalizeFolderPath(path);
    if (target == normalizeFolderPath(_folders.defaultFolder)) return;
    final list = await _storedSaveLocations(_folders);
    await _folders.saveSaveLocations([
      for (final p in list)
        if (normalizeFolderPath(p) != target) p,
    ]);
  }
}

/// 숨긴 곡(폴더를 빼서 기록만 남은 곡)의 수.
class CountHiddenTracks implements UseCase<int, NoParams> {
  const CountHiddenTracks(this._library);

  final LibraryRepository _library;

  @override
  Future<int> call(NoParams _) => _library.hiddenCount();
}

/// 숨긴 곡의 남은 기록을 모두 지운다. 지운 곡 수를 돌려준다.
class PurgeHiddenTracks implements UseCase<int, NoParams> {
  const PurgeHiddenTracks(this._library);

  final LibraryRepository _library;

  @override
  Future<int> call(NoParams _) => _library.purgeHidden();
}

/// 폴더를 목록에서 빼고, 그 폴더에서 불러온 곡을 보관함에서 숨긴다 (음악 파일은 그대로).
/// 곡 행과 재생 기록 · 좋아요 · 재생목록 · 커버는 남기고, 다시 불러오면 숨김만 풀린다.
/// 남은 폴더 안에도 있는 곡(하위 폴더로 겹칠 때)은 숨기지 않는다. 기본 저장 위치는 뺄 수 없다.
/// 돌려주는 값은 보관함에서 지운 곡의 id (폴더를 못 뺐으면 null).
/// [cancelled]가 true가 되면 지우기를 멈추고 폴더를 목록에 되돌린다 (이미 지운 곡은 id로 돌려준다).
class RemoveLoadedFolder implements UseCase<Set<String>?, String> {
  const RemoveLoadedFolder(this._folders, this._library);

  final LoadedFolderRepository _folders;
  final LibraryRepository _library;

  @override
  Future<Set<String>?> call(String path, {bool Function()? cancelled}) async {
    final target = normalizeFolderPath(path);
    if (target == normalizeFolderPath(_folders.defaultFolder)) return null;
    final extra = await _folders.loadExtra();
    final kept = [
      for (final p in extra)
        if (normalizeFolderPath(p) != target) p,
    ];
    if (kept.length == extra.length) return null;
    await _folders.saveExtra(kept);
    final remaining = [_folders.defaultFolder, ...kept];
    final tracks = await _library.watchTracks().first;
    final removed = <String>{};
    for (final t in tracks) {
      if (cancelled?.call() ?? false) {
        await _folders.saveExtra(extra);
        return removed;
      }
      if (isInsideFolder(t.folder, target) &&
          !remaining.any((f) => isInsideFolder(t.folder, f))) {
        await _library.hide(t.id);
        removed.add(t.id);
      }
    }
    return removed;
  }
}
