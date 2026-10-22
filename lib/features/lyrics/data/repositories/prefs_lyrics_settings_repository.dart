import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/lyrics_settings.dart';
import '../../domain/repositories/lyrics_settings_repository.dart';

/// shared_preferences에 가사 · 싱크 설정을 저장한다.
class PrefsLyricsSettingsRepository implements LyricsSettingsRepository {
  static const _latencyKey = 'lyrics.stampLatencyMs';
  static const _themeKey = 'lyrics.theme';
  static const _coverKey = 'lyrics.coverBackground';
  static const _overlayKey = 'lyrics.overlay';

  @override
  Future<LyricsSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LyricsSettings(
      latencyMs: (prefs.getInt(_latencyKey) ?? LyricsSettings.defaultLatencyMs)
          .clamp(0, LyricsSettings.maxLatencyMs),
      theme:
          LyricsTheme.values.asNameMap()[prefs.getString(_themeKey)] ??
          LyricsTheme.list,
      coverBackground: prefs.getBool(_coverKey) ?? false,
      overlay: prefs.getBool(_overlayKey) ?? false,
    );
  }

  @override
  Future<void> saveLatency(int milliseconds) async =>
      (await SharedPreferences.getInstance()).setInt(_latencyKey, milliseconds);

  @override
  Future<void> saveTheme(LyricsTheme theme) async =>
      (await SharedPreferences.getInstance()).setString(_themeKey, theme.name);

  @override
  Future<void> saveCoverBackground(bool on) async =>
      (await SharedPreferences.getInstance()).setBool(_coverKey, on);

  @override
  Future<void> saveOverlay(bool on) async =>
      (await SharedPreferences.getInstance()).setBool(_overlayKey, on);
}
