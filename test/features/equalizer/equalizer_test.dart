import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:music_download_play_app/features/equalizer/domain/repositories/equalizer_repository.dart';
import 'package:music_download_play_app/features/equalizer/presentation/bloc/equalizer_cubit.dart';

import '../../helpers/fakes.dart';

const _info = EqualizerInfo(
  bandHz: [60, 230, 910, 3600, 14000],
  minDb: -15,
  maxDb: 15,
  bassBoostSupported: true,
  virtualizerSupported: true,
  reverbSupported: true,
  limiterSupported: true,
);

void main() {
  late MemoryEqualizerRepository repo;

  Future<EqualizerCubit> make({
    EqualizerInfo? info = _info,
    EqualizerSettings settings = const EqualizerSettings(),
  }) async {
    await setUpTestDependencies();
    repo = MemoryEqualizerRepository(info: info, settings: settings);
    sl
      ..unregister<EqualizerRepository>()
      ..registerSingleton<EqualizerRepository>(repo);
    final cubit = sl<EqualizerCubit>();
    await cubit.load();
    return cubit;
  }

  test('기본은 꺼짐이고 대역은 평평하다', () async {
    final cubit = await make();
    expect(cubit.state.settings.enabled, isFalse);
    expect(cubit.state.settings.levels, List.filled(5, 0.0));
    expect(repo.applied?.enabled, isFalse);
  });

  test('지원하지 않는 환경이면 supported가 false다', () async {
    final cubit = await make(info: null);
    expect(cubit.state.supported, isFalse);
  });

  test('켜면 바로 저장하고 엔진에 반영한다', () async {
    final cubit = await make();
    await cubit.setEnabled(true);
    expect(repo.settings.enabled, isTrue);
    expect(repo.applied?.enabled, isTrue);
  });

  test('프리셋을 고르면 소리에는 바로 반영되지만 저장 전에는 저장되지 않는다', () async {
    final cubit = await make();
    cubit.selectPreset(EqualizerPreset.bass);
    expect(cubit.state.settings.preset, EqualizerPreset.bass);
    expect(cubit.state.settings.levels.first, 6);
    expect(cubit.state.settings.levels.last, 0);
    expect(repo.applied?.preset, EqualizerPreset.bass);
    expect(cubit.state.dirty, isTrue);
    expect(repo.settings.preset, EqualizerPreset.flat);
    await cubit.save();
    expect(repo.settings.preset, EqualizerPreset.bass);
    expect(cubit.state.dirty, isFalse);
  });

  test('대역을 만지면 직접 조절이 되고 허용 범위로 자른다', () async {
    final cubit = await make();
    cubit.setBand(2, 40);
    expect(cubit.state.settings.preset, EqualizerPreset.custom);
    expect(cubit.state.settings.levels[2], 15);
    expect(repo.applied?.levels[2], 15);
  });

  test('저장하지 않고 나가면 저장된 값으로 소리를 되돌린다', () async {
    final cubit = await make();
    cubit.selectPreset(EqualizerPreset.rock);
    cubit.discard();
    expect(cubit.state.settings.preset, EqualizerPreset.flat);
    expect(cubit.state.dirty, isFalse);
    expect(repo.applied?.preset, EqualizerPreset.flat);
  });

  test('켜고 끄기는 저장 전 손본 값을 저장하지 않는다', () async {
    final cubit = await make();
    cubit.selectPreset(EqualizerPreset.rock);
    await cubit.setEnabled(true);
    expect(repo.settings.enabled, isTrue);
    expect(repo.settings.preset, EqualizerPreset.flat);
    expect(cubit.state.settings.preset, EqualizerPreset.rock);
  });

  test('저장된 값의 대역 수가 기기와 다르면 프리셋 곡선으로 맞춘다', () async {
    final cubit = await make(
      settings: const EqualizerSettings(
        enabled: true,
        preset: EqualizerPreset.rock,
        levels: [1, 2, 3],
      ),
    );
    expect(cubit.state.settings.levels.length, 5);
    expect(cubit.state.settings.levels.first, 4);
    expect(cubit.state.settings.enabled, isTrue);
  });

  test('입체 음향 · 공간 울림 · 클리핑 방지를 바꾸고 저장한다', () async {
    final cubit = await make();
    expect(cubit.state.settings.limiter, isTrue); // 기본 켜짐
    cubit.setVirtualizer(.5);
    expect(repo.applied?.virtualizer, .5);
    cubit.selectReverb(EqualizerReverb.largeHall);
    cubit.setLimiter(false);
    await cubit.save();
    expect(repo.settings.reverb, EqualizerReverb.largeHall);
    expect(repo.settings.limiter, isFalse);
    expect(repo.settings.virtualizer, .5);
  });

  test('기기가 지원하지 않는 효과는 저장값이 있어도 꺼 둔다', () async {
    final cubit = await make(
      info: const EqualizerInfo(
        bandHz: [60, 230, 910, 3600, 14000],
        minDb: -15,
        maxDb: 15,
        bassBoostSupported: false,
      ),
      settings: const EqualizerSettings(
        virtualizer: .7,
        reverb: EqualizerReverb.plate,
        bassBoost: .4,
      ),
    );
    expect(cubit.state.settings.virtualizer, 0);
    expect(cubit.state.settings.reverb, EqualizerReverb.none);
    expect(cubit.state.settings.bassBoost, 0);
  });

  test('처음으로는 평평하게 되돌리고 저장은 따로 누른다', () async {
    final cubit = await make();
    cubit.selectPreset(EqualizerPreset.rock);
    cubit.setBassBoost(.8);
    await cubit.save();
    cubit.reset();
    expect(cubit.state.settings.preset, EqualizerPreset.flat);
    expect(cubit.state.settings.bassBoost, 0);
    expect(cubit.state.settings.levels, List.filled(5, 0.0));
    expect(repo.settings.preset, EqualizerPreset.rock);
    expect(cubit.state.dirty, isTrue);
  });

  test('대역 수가 달라도 프리셋은 범위를 지킨다', () {
    for (final preset in EqualizerPreset.values) {
      for (final n in [1, 3, 5, 10]) {
        final levels = preset.levelsFor(n, minDb: -3, maxDb: 3);
        expect(levels.length, n);
        expect(levels.every((v) => v >= -3 && v <= 3), isTrue);
      }
    }
  });
}
