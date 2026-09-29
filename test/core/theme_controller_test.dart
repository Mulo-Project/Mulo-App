import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';

class _MemoryStore implements ThemePreferenceStore {
  _MemoryStore([this.saved]);

  String? saved;

  @override
  Future<String?> loadPresetId() async => saved;

  @override
  Future<void> savePresetId(String id) async => saved = id;
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
    expect(s.palette.accent, AppPalette.lime);
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

  test('모든 프리셋은 배경 검정 · 강조 색 대비 7:1 이상', () {
    for (final p in ThemePreset.values) {
      expect(p.palette.background, AppPalette.black, reason: p.name);
      expect(
        contrastRatio(p.palette.accent, p.palette.background),
        greaterThanOrEqualTo(7),
        reason: p.name,
      );
    }
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
