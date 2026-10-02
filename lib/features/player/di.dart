import 'package:get_it/get_it.dart';

import 'data/datasources/audio_output_source.dart';
import 'data/repositories/platform_audio_output_repository.dart';
import 'domain/repositories/audio_output_repository.dart';
import 'domain/usecases/get_audio_output.dart';
import 'presentation/bloc/audio_output_cubit.dart';
import 'presentation/bloc/now_playing_cubit.dart';

void registerPlayer(GetIt sl) {
  sl
    ..registerFactory(NowPlayingCubit.new)
    ..registerLazySingleton(AudioOutputSource.new)
    ..registerLazySingleton<AudioOutputRepository>(
      () => PlatformAudioOutputRepository(sl()),
    )
    ..registerFactory(() => GetAudioOutput(sl()))
    ..registerFactory(() => AudioOutputCubit(sl()));
}
