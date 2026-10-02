/// 다운로드 설정 저장소 (기본 저장 위치).
abstract interface class DownloadSettingsRepository {
  /// 기본 저장 위치. 고른 적이 없으면 앱 기본 폴더.
  Future<String> loadSavePath();

  Future<void> saveSavePath(String path);

  /// 폴더 선택기. 고른 폴더 경로, 취소하면 null.
  Future<String?> pickFolder();
}
