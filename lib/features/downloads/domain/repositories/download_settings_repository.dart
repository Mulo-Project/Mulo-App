import '../entities/download_options.dart';

/// 다운로드 설정 저장소 (기본 저장 위치 · 형식).
abstract interface class DownloadSettingsRepository {
  /// 이 기기에서 고를 수 있는 저장 형식 (OS별 정책).
  List<AudioFormat> selectableFormats();

  /// 실제로 받을 때 쓸 저장 위치: 고정한 폴더 → 마지막에 받은 폴더 → 앱 기본 폴더 순서.
  Future<String> loadSavePath();

  /// 고정한(체크한) 저장 위치. 고정하지 않았으면 빈 문자열.
  Future<String> loadFixedSavePath();

  /// 저장 위치를 고정한다.
  Future<void> saveSavePath(String path);

  /// 고정을 푼다 (이후에는 마지막에 받은 폴더가 기준).
  Future<void> clearSavePath();

  /// 마지막에 받은 폴더를 기억한다.
  Future<void> saveLastSavePath(String path);

  /// 기본 저장 형식 (설정). 이 기기에서 못 고르는 형식이면 고를 수 있는 첫 형식.
  Future<AudioFormat> loadFormat();

  Future<void> saveFormat(AudioFormat format);

  /// 폴더 선택기. 고른 폴더 경로, 취소하면 null.
  Future<String?> pickFolder();
}
