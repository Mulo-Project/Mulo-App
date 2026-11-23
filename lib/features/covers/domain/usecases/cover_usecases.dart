import '../../../../core/usecase/usecase.dart';
import '../entities/cover_art.dart';
import '../repositories/cover_repository.dart';

class LoadCovers implements UseCase<Map<String, CoverArt>, NoParams> {
  const LoadCovers(this._repo);

  final CoverRepository _repo;

  @override
  Future<Map<String, CoverArt>> call(NoParams _) => _repo.loadAll();
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
  const SaveCoverParams(
    this.key,
    this.sourcePath, [
    this.transform = CoverTransform.identity,
  ]);

  final String key;
  final String sourcePath;
  final CoverTransform transform;
}

/// 이미 고른 파일을 [SaveCoverParams.key]의 커버로 저장한다. 저장된 커버를 돌려준다.
class SaveCover implements UseCase<CoverArt, SaveCoverParams> {
  const SaveCover(this._repo);

  final CoverRepository _repo;

  @override
  Future<CoverArt> call(SaveCoverParams p) =>
      _repo.save(p.key, p.sourcePath, transform: p.transform);
}

class SaveWebCoverParams {
  const SaveWebCoverParams(
    this.key,
    this.url, [
    this.transform = CoverTransform.identity,
  ]);

  final String key;
  final String url;
  final CoverTransform transform;
}

/// 웹 이미지를 [SaveWebCoverParams.key]의 커버로 쓴다. 파일은 받지 않고 주소만 저장한다.
class SaveWebCover implements UseCase<CoverArt, SaveWebCoverParams> {
  const SaveWebCover(this._repo);

  final CoverRepository _repo;

  @override
  Future<CoverArt> call(SaveWebCoverParams p) =>
      _repo.saveUrl(p.key, p.url, transform: p.transform);
}

class SetCoverTransformParams {
  const SetCoverTransformParams(this.key, this.transform);

  final String key;
  final CoverTransform transform;
}

/// 이미 붙인 커버의 확대 · 위치만 바꾼다.
class SetCoverTransform implements UseCase<void, SetCoverTransformParams> {
  const SetCoverTransform(this._repo);

  final CoverRepository _repo;

  @override
  Future<void> call(SetCoverTransformParams p) =>
      _repo.saveTransform(p.key, p.transform);
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
