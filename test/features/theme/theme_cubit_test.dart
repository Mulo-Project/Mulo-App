import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/theme/domain/entities/theme_settings.dart';
import 'package:music_download_play_app/features/theme/domain/usecases/theme_usecases.dart';
import 'package:music_download_play_app/features/theme/presentation/bloc/theme_cubit.dart';

import '../../helpers/fakes.dart';

ThemeCubit _cubit(MemoryThemeSettingsRepository repo) => ThemeCubit(
  loadSettings: LoadThemeSettings(repo),
  savePreset: SaveThemePreset(repo),
  saveMode: SaveThemeMode(repo),
  saveFollowMood: SaveFollowMood(repo),
);

void main() {
  test('처음에는 바이올렛 프리셋 · 다크', () {
    final c = _cubit(MemoryThemeSettingsRepository());
    addTearDown(c.close);
    expect(c.state.preset, ThemePreset.violet);
    expect(c.state.dark.accent, AppPalette.lime);
    expect(c.state.mode, AppThemeMode.dark);
    expect(c.state.materialMode, ThemeMode.dark);
  });

  blocTest<ThemeCubit, ThemeState>(
    'selectPreset은 적용하고 저장한다',
    build: () => _cubit(MemoryThemeSettingsRepository()),
    act: (c) => c.selectPreset(ThemePreset.ocean),
    verify: (c) {
      expect(c.state.preset, ThemePreset.ocean);
      expect(c.state.sourceId, ThemePreset.ocean.id);
    },
  );

  test('저장된 프리셋 · 모드를 불러온다', () async {
    final repo = MemoryThemeSettingsRepository(
      ThemeSettings(presetId: ThemePreset.sunset.id, mode: AppThemeMode.light),
    );
    final c = _cubit(repo);
    addTearDown(c.close);
    await c.load();
    expect(c.state.preset, ThemePreset.sunset);
    expect(c.state.mode, AppThemeMode.light);
  });

  test('selectMode는 저장된다', () async {
    final repo = MemoryThemeSettingsRepository();
    final c = _cubit(repo);
    addTearDown(c.close);
    await c.selectMode(AppThemeMode.light);
    expect(repo.settings.mode, AppThemeMode.light);
  });

  test('reset은 고른 프리셋으로 돌아간다', () async {
    final c = _cubit(MemoryThemeSettingsRepository());
    addTearDown(c.close);
    await c.selectPreset(ThemePreset.rose);
    await c.apply(ThemePreset.gold); // 곡 분위기 같은 임시 소스라고 가정
    await c.reset();
    expect(c.state.sourceId, ThemePreset.rose.id);
  });

  test('모든 프리셋: 다크는 검정 배경 · 대비 7:1, 라이트는 밝은 배경 · 대비 2:1', () {
    for (final p in ThemePreset.values) {
      final dark = p.paletteFor(Brightness.dark);
      final light = p.paletteFor(Brightness.light);
      expect(dark.background, AppPalette.black, reason: p.name);
      expect(
        contrastRatio(dark.accent, dark.background),
        greaterThanOrEqualTo(7),
        reason: p.name,
      );
      expect(light.brightness, Brightness.light, reason: p.name);
      expect(
        contrastRatio(light.accent, light.background),
        greaterThanOrEqualTo(2),
        reason: p.name,
      );
    }
  });
}
