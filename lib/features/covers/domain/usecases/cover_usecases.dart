import '../../../../core/usecase/usecase.dart';
import '../repositories/cover_repository.dart';

class LoadCovers implements UseCase<Map<String, String>, NoParams> {
  const LoadCovers(this._repo);

  final CoverRepository _repo;

  @override
  Future<Map<String, String>> call(NoParams _) => _repo.loadAll();
}

/// 기기에서 사진을 골라 [key]의 커버로 저장한다. 저장된 경로, 취소하면 null.
class PickCoverFromDevice implements UseCase<String?, String> {
  const PickCoverFromDevice(this._source, this._repo);

  final CoverImageSource _source;
  final CoverRepository _repo;

  @override
  Future<String?> call(String key) async {
    final picked = await _source.pickFromDevice();
    if (picked == null) return null;
    return _repo.save(key, picked);
  }
}

class ClearCover implements UseCase<void, String> {
  const ClearCover(this._repo);

  final CoverRepository _repo;

  @override
  Future<void> call(String key) => _repo.remove(key);
}

/// 기기에서 사진 한 장만 고른다 (아직 어느 커버로도 저장하지 않는다). 취소하면 null.
class PickImageFile implements UseCase<String?, NoParams> {
  const PickImageFile(this._source);

  final CoverImageSource _source;

  @override
  Future<String?> call(NoParams _) => _source.pickFromDevice();
}

class SaveCoverParams {
  const SaveCoverParams(this.key, this.sourcePath);

  final String key;
  final String sourcePath;
}

/// 이미 고른 파일을 [SaveCoverParams.key]의 커버로 저장한다. 저장된 경로를 돌려준다.
class SaveCover implements UseCase<String, SaveCoverParams> {
  const SaveCover(this._repo);

  final CoverRepository _repo;

  @override
  Future<String> call(SaveCoverParams p) => _repo.save(p.key, p.sourcePath);
}

class LoadCoverColors implements UseCase<Map<String, int>, NoParams> {
  const LoadCoverColors(this._repo);

  final CoverColorRepository _repo;

  @override
  Future<Map<String, int>> call(NoParams _) => _repo.loadAll();
}

class SetCoverColorParams {
  const SetCoverColorParams(this.key, this.color);

  final String key;

  /// ARGB 값.
  final int color;
}

class SetCoverColor implements UseCase<void, SetCoverColorParams> {
  const SetCoverColor(this._repo);

  final CoverColorRepository _repo;

  @override
  Future<void> call(SetCoverColorParams p) => _repo.save(p.key, p.color);
}

/// 고른 색을 지우고 자동 색으로 되돌린다.
class ClearCoverColor implements UseCase<void, String> {
  const ClearCoverColor(this._repo);

  final CoverColorRepository _repo;

  @override
  Future<void> call(String key) => _repo.remove(key);
}
