import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_source/theme_presets.dart';
import 'theme_source/theme_source.dart';
import 'tokens/app_palette.dart';

/// 화면 모드 (설정 › 테마). 기기 설정을 따르지 않고 앱에서 고른다 (기본 다크, D-018).
/// 배경 밝기만 정하고, 색은 프리셋이 정한다.
enum AppThemeMode {
  dark,
  light;

  static const AppThemeMode initial = dark;

  ThemeMode get material => switch (this) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
  };
}

@immutable
class ThemeState {
  const ThemeState({
    required this.sourceId,
    required this.dark,
    required this.light,
    this.preset = ThemePreset.initial,
    this.mode = AppThemeMode.initial,
  });

  /// 지금 화면에 적용된 소스 (프리셋 · 곡 분위기 등).
  final String sourceId;

  /// 같은 소스의 다크 · 라이트 팔레트. 어느 쪽을 쓸지는 [mode] · 시스템 설정이 정한다.
  final AppPalette dark;
  final AppPalette light;

  /// 사용자가 설정에서 고른 프리셋. 곡 분위기 테마가 적용 중이어도 유지된다.
  final ThemePreset preset;
  final AppThemeMode mode;

  AppPalette paletteFor(Brightness b) => b == Brightness.dark ? dark : light;

  ThemeState copyWith({
    String? sourceId,
    AppPalette? dark,
    AppPalette? light,
    ThemePreset? preset,
    AppThemeMode? mode,
  }) => ThemeState(
    sourceId: sourceId ?? this.sourceId,
    dark: dark ?? this.dark,
    light: light ?? this.light,
    preset: preset ?? this.preset,
    mode: mode ?? this.mode,
  );
}

/// 테마 설정 저장소 (프리셋 · 화면 모드).
abstract interface class ThemePreferenceStore {
  Future<String?> loadPresetId();
  Future<void> savePresetId(String id);
  Future<String?> loadMode();
  Future<void> saveMode(String mode);
}

class SharedPrefsThemePreferenceStore implements ThemePreferenceStore {
  static const _presetKey = 'theme.preset';
  static const _modeKey = 'theme.mode';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> loadPresetId() async => (await _prefs).getString(_presetKey);

  @override
  Future<void> savePresetId(String id) async =>
      (await _prefs).setString(_presetKey, id);

  @override
  Future<String?> loadMode() async => (await _prefs).getString(_modeKey);

  @override
  Future<void> saveMode(String mode) async =>
      (await _prefs).setString(_modeKey, mode);
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => SharedPrefsThemePreferenceStore(),
);

/// 현재 테마를 가진다. 소스를 [apply]하면 다크 · 라이트 팔레트가 바뀌고,
/// MaterialApp의 테마 애니메이션이 [AppThemeTokens.lerp]로 부드럽게 넘긴다.
class ThemeController extends Notifier<ThemeState> {
  int _request = 0;
  bool _touched = false;

  @override
  ThemeState build() {
    Future.microtask(_restore);
    const p = ThemePreset.initial;
    return ThemeState(
      sourceId: p.id,
      dark: p.paletteFor(Brightness.dark),
      light: p.paletteFor(Brightness.light),
    );
  }

  Future<void> _restore() async {
    final store = ref.read(themePreferenceStoreProvider);
    final preset = ThemePreset.fromId(await store.loadPresetId());
    final mode = AppThemeMode.values.asNameMap()[await store.loadMode()];
    // 저장 값을 읽는 사이에 사용자가 이미 바꿨으면 덮어쓰지 않는다.
    if (_touched) return;
    if (mode != null) state = state.copyWith(mode: mode);
    if (preset != null) await _applyPreset(preset);
  }

  /// 설정에서 프리셋을 고른다. 저장해서 다음 실행에도 유지한다.
  Future<void> selectPreset(ThemePreset preset) async {
    _touched = true;
    await _applyPreset(preset);
    await ref.read(themePreferenceStoreProvider).savePresetId(preset.id);
  }

  /// 화면 모드(다크 · 라이트)를 고른다. 저장한다.
  Future<void> selectMode(AppThemeMode mode) async {
    _touched = true;
    state = state.copyWith(mode: mode);
    await ref.read(themePreferenceStoreProvider).saveMode(mode.name);
  }

  Future<void> _applyPreset(ThemePreset preset) async {
    await apply(preset);
    state = state.copyWith(preset: preset);
  }

  /// 임의의 소스 적용 (곡 분위기 등). 저장하지 않는다.
  Future<void> apply(ThemeSource source) async {
    if (source.id == state.sourceId) return;
    final request = ++_request;
    final dark = await source.resolve(Brightness.dark);
    final light = await source.resolve(Brightness.light);
    // 곡이 빠르게 바뀌면 늦게 끝난 이전 추출 결과는 버린다.
    if (request != _request) return;
    state = state.copyWith(sourceId: source.id, dark: dark, light: light);
  }

  /// 고른 프리셋으로 돌아간다 (예: 곡 분위기 따라가기를 끌 때).
  Future<void> reset() => apply(state.preset);
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);
