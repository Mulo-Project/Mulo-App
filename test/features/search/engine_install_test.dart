import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/engine/presentation/bloc/engine_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  test('EngineCubit: 확인하고 설치하면 설치됨으로 바뀐다', () async {
    final manager = FakeEngineManager();
    await setUpTestDependencies(engineManager: manager);
    final cubit = sl<EngineCubit>();
    await cubit.load();
    expect(cubit.state.status!.installed, isFalse);
    await cubit.install();
    expect(cubit.state.status!.installed, isTrue);
    expect(cubit.state.failed, isFalse);
  });

  test('EngineCubit: 설치에 실패하면 failed', () async {
    await setUpTestDependencies(
      engineManager: FakeEngineManager(failInstall: true),
    );
    final cubit = sl<EngineCubit>();
    await cubit.load();
    await cubit.install();
    expect(cubit.state.failed, isTrue);
    expect(cubit.state.status!.installed, isFalse);
  });
}
