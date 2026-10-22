import '../entities/lyrics_settings.dart';

/// 가사 · 싱크 설정 저장소.
abstract interface class LyricsSettingsRepository {
  Future<LyricsSettings> load();
  Future<void> saveLatency(int milliseconds);
  Future<void> saveTheme(LyricsTheme theme);
  Future<void> saveCoverBackground(bool on);
  Future<void> saveOverlay(bool on);
}
