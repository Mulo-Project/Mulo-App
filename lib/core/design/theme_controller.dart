import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_source/theme_presets.dart';
import 'theme_source/theme_source.dart';
import 'tokens/app_palette.dart';

@immutable
class ThemeState {
  const ThemeState({
    required this.sourceId,
    required this.palette,
    this.preset = ThemePreset.initial,
  });

  /// 지금 화면에 적용된 소스 (프리셋 · 곡 분위기 등).
  final String sourceId;
  final AppPalette palette;

  /// 사용자가 설정에서 고른 프리셋. 곡 분위기 테마가 적용 중이어도 유지된다.
  final ThemePreset preset;
}

/// 고른 테마 프리셋 저장소.
abstract interface class ThemePreferenceStore {
  Future<String?> loadPresetId();
  Future<void> savePresetId(String id);
}

class SharedPrefsThemePreferenceStore implements ThemePreferenceStore {
  static const _key = 'theme.preset';

  @override
  Future<String?> loadPresetId() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> savePresetId(String id) async =>
      (await SharedPreferences.getInstance()).setString(_key, id);
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => SharedPrefsThemePreferenceStore(),
);

/// 현재 테마를 가진다. 소스를 [apply]하면 팔레트가 바뀌고,
/// MaterialApp의 테마 애니메이션이 [AppThemeTokens.lerp]로 부드럽게 넘긴다.
class ThemeController extends Notifier<ThemeState> {
  int _request = 0;

  @override
  ThemeState build() {
    Future.microtask(_restore);
    return ThemeState(
      sourceId: ThemePreset.initial.id,
      palette: ThemePreset.initial.palette,
    );
  }

  Future<void> _restore() async {
    final saved = ThemePreset.fromId(
      await ref.read(themePreferenceStoreProvider).loadPresetId(),
    );
    // 저장 값을 읽는 사이에 사용자가 이미 바꿨으면 덮어쓰지 않는다.
    if (saved == null || _request > 0) return;
    await _applyPreset(saved);
  }

  /// 설정에서 프리셋을 고른다. 저장해서 다음 실행에도 유지한다.
  Future<void> selectPreset(ThemePreset preset) async {
    await _applyPreset(preset);
    await ref.read(themePreferenceStoreProvider).savePresetId(preset.id);
  }

  Future<void> _applyPreset(ThemePreset preset) async {
    await apply(preset);
    state = ThemeState(
      sourceId: state.sourceId,
      palette: state.palette,
      preset: preset,
    );
  }

  /// 임의의 소스 적용 (곡 분위기 등). 저장하지 않는다.
  Future<void> apply(ThemeSource source) async {
    if (source.id == state.sourceId) return;
    final request = ++_request;
    final palette = await source.resolve();
    // 곡이 빠르게 바뀌면 늦게 끝난 이전 추출 결과는 버린다.
    if (request != _request) return;
    state = ThemeState(
      sourceId: source.id,
      palette: palette,
      preset: state.preset,
    );
  }

  /// 고른 프리셋으로 돌아간다 (예: 곡 분위기 따라가기를 끌 때).
  Future<void> reset() => apply(state.preset);
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);
