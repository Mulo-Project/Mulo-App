import 'package:get_it/get_it.dart';

import '../../core/platform/equalizer_channel.dart';
import 'data/repositories/platform_equalizer_repository.dart';
import 'domain/repositories/equalizer_repository.dart';
import 'domain/usecases/equalizer_usecases.dart';
import 'presentation/bloc/equalizer_cubit.dart';
import 'presentation/bloc/equalizer_library_cubit.dart';

void registerEqualizer(GetIt sl) {
  sl
    ..registerLazySingleton(EqualizerChannel.new)
    ..registerLazySingleton<EqualizerRepository>(
      () => PlatformEqualizerRepository(sl()),
    )
    ..registerFactory(() => LoadEqualizer(sl()))
    ..registerFactory(() => ApplyEqualizer(sl()))
    ..registerFactory(() => SaveEqualizer(sl()))
    ..registerFactory(() => SetEqualizerDeviceProfile(sl()))
    ..registerFactory(() => LoadEqualizerPresets(sl()))
    ..registerFactory(() => SaveEqualizerPreset(sl()))
    ..registerFactory(() => DeleteEqualizerPreset(sl()))
    ..registerFactory(() => LoadEqualizerDevices(sl()))
    ..registerFactory(() => AssignEqualizerPreset(sl()))
    ..registerFactory(
      () => EqualizerLibraryCubit(
        loadPresets: sl(),
        savePreset: sl(),
        deletePreset: sl(),
        loadDevices: sl(),
        assignPreset: sl(),
        watchDevice: sl(),
      ),
    )
    ..registerFactory(() => WatchEqualizerDevice(sl()))
    ..registerFactory(
      () => EqualizerCubit(
        loadEqualizer: sl(),
        applyEqualizer: sl(),
        saveEqualizer: sl(),
        setDeviceProfile: sl(),
        watchDevice: sl(),
      ),
    );
}
