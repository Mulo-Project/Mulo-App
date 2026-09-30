import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/theme_settings.dart';
import '../../domain/repositories/theme_settings_repository.dart';

/// shared_preferences에 테마 설정을 저장한다.
class PrefsThemeSettingsRepository implements ThemeSettingsRepository {
  static const _presetKey = 'theme.preset';
  static const _modeKey = 'theme.mode';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<ThemeSettings> load() async {
    final prefs = await _prefs;
    return ThemeSettings(
      presetId: prefs.getString(_presetKey),
      // 예전 값 'system' 등 모르는 값은 기본(다크).
      mode:
          AppThemeMode.values.asNameMap()[prefs.getString(_modeKey)] ??
          AppThemeMode.initial,
    );
  }

  @override
  Future<void> savePreset(String presetId) async =>
      (await _prefs).setString(_presetKey, presetId);

  @override
  Future<void> saveMode(AppThemeMode mode) async =>
      (await _prefs).setString(_modeKey, mode.name);
}
