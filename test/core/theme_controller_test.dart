import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';

class _MemoryStore implements ThemePreferenceStore {
  _MemoryStore([this.saved]);

  String? saved;
  String? savedMode;

  @override
  Future<String?> loadPresetId() async => saved;

  @override
  Future<void> savePresetId(String id) async => saved = id;

  @override
  Future<String?> loadMode() async => savedMode;

  @override
  Future<void> saveMode(String mode) async => savedMode = mode;
}

ProviderContainer _container(_MemoryStore store) => ProviderContainer(
  overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
);

void main() {
  test('처음에는 바이올렛 프리셋', () {
    final c = _container(_MemoryStore());
    addTearDown(c.dispose);
    final s = c.read(themeControllerProvider);
    expect(s.preset, ThemePreset.violet);
    expect(s.dark.accent, AppPalette.lime);
    expect(s.mode, AppThemeMode.system);
  });

  test('selectPreset은 적용하고 저장한다', () async {
    final store = _MemoryStore();
    final c = _container(store);
    addTearDown(c.dispose);
    await c
        .read(themeControllerProvider.notifier)
        .selectPreset(ThemePreset.ocean);
    final s = c.read(themeControllerProvider);
    expect(s.preset, ThemePreset.ocean);
    expect(s.sourceId, ThemePreset.ocean.id);
    expect(store.saved, ThemePreset.ocean.id);
  });

  test('저장된 프리셋을 불러온다', () async {
    final c = _container(_MemoryStore(ThemePreset.sunset.id));
    addTearDown(c.dispose);
    c.read(themeControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(themeControllerProvider).preset, ThemePreset.sunset);
  });

  test('모든 프리셋: 다크는 검정 배경 · 대비 7:1, 라이트는 밝은 배경 · 대비 3:1', () {
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
        greaterThanOrEqualTo(3),
        reason: p.name,
      );
    }
  });

  test('selectMode는 적용하고 저장한다', () async {
    final store = _MemoryStore();
    final c = _container(store);
    addTearDown(c.dispose);
    await c
        .read(themeControllerProvider.notifier)
        .selectMode(AppThemeMode.light);
    expect(c.read(themeControllerProvider).mode, AppThemeMode.light);
    expect(store.savedMode, 'light');
  });

  test('저장된 화면 모드를 불러온다', () async {
    final c = _container(_MemoryStore()..savedMode = 'dark');
    addTearDown(c.dispose);
    c.read(themeControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(themeControllerProvider).mode, AppThemeMode.dark);
  });

  test('reset은 고른 프리셋으로 돌아간다', () async {
    final c = _container(_MemoryStore());
    addTearDown(c.dispose);
    final ctrl = c.read(themeControllerProvider.notifier);
    await ctrl.selectPreset(ThemePreset.rose);
    await ctrl.apply(ThemePreset.gold); // 곡 분위기 같은 임시 소스라고 가정
    await ctrl.reset();
    expect(c.read(themeControllerProvider).sourceId, ThemePreset.rose.id);
  });
}
