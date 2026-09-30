/// 커버 이미지 저장소: 고른 파일을 앱 폴더로 복사하고 키 → 경로를 기억한다.
abstract interface class CoverRepository {
  Future<Map<String, String>> loadAll();

  /// [sourcePath]를 저장소로 복사하고 저장된 경로를 돌려준다.
  Future<String> save(String key, String sourcePath);
  Future<void> remove(String key);
}

/// 기기에서 이미지 한 장을 고른다 (사진 선택기 · 파일 대화상자).
abstract interface class CoverImageSource {
  /// 고른 파일 경로. 취소하면 null.
  Future<String?> pickFromDevice();
}
