import '../entities/theme_settings.dart';

/// 테마 설정 저장소 (프리셋 · 화면 모드).
abstract interface class ThemeSettingsRepository {
  Future<ThemeSettings> load();
  Future<void> savePreset(String presetId);
  Future<void> saveMode(AppThemeMode mode);
  Future<void> saveFollowMood(bool value);
}
