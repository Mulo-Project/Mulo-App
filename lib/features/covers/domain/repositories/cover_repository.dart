import '../entities/cover_art.dart';

/// 커버 이미지 저장소: 키 → 커버. 기기 사진은 앱 폴더로 복사하고, 웹 이미지는 주소만 기억한다.
abstract interface class CoverRepository {
  Future<Map<String, CoverArt>> loadAll();

  /// [sourcePath]를 저장소로 복사하고 저장된 커버를 돌려준다.
  Future<CoverArt> save(
    String key,
    String sourcePath, {
    CoverTransform transform = CoverTransform.identity,
  });

  /// 웹 이미지 [url]을 복사 없이 주소만 저장한다.
  Future<CoverArt> saveUrl(
    String key,
    String url, {
    CoverTransform transform = CoverTransform.identity,
  });

  /// 이미지는 그대로 두고 자르는 위치 · 확대만 바꾼다.
  Future<void> saveTransform(String key, CoverTransform transform);
  Future<void> remove(String key);
}

/// 커버 색 저장소: 키 → ARGB 값. 테마와 상관없이 고른 색 그대로 쓴다.
abstract interface class CoverColorRepository {
  Future<Map<String, int>> loadAll();
  Future<void> save(String key, int color);
  Future<void> remove(String key);
}

/// 기기에서 이미지 한 장을 고른다 (사진 선택기 · 파일 대화상자).
abstract interface class CoverImageSource {
  /// 고른 파일 경로. 취소하면 null.
  Future<String?> pickFromDevice();
}
