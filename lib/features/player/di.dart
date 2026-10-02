import 'package:get_it/get_it.dart';

import 'data/datasources/audio_output_source.dart';
import 'data/repositories/platform_audio_output_repository.dart';
import 'data/repositories/prefs_player_style_repository.dart';
import 'domain/repositories/audio_output_repository.dart';
import 'domain/repositories/player_style_repository.dart';
import 'domain/usecases/get_audio_output.dart';
import 'domain/usecases/player_style_usecases.dart';
import 'presentation/bloc/audio_output_cubit.dart';
import 'presentation/bloc/now_playing_cubit.dart';
import 'presentation/bloc/player_style_cubit.dart';

void registerPlayer(GetIt sl) {
  sl
    ..registerFactory(NowPlayingCubit.new)
    ..registerLazySingleton(AudioOutputSource.new)
    ..registerLazySingleton<AudioOutputRepository>(
      () => PlatformAudioOutputRepository(sl()),
    )
    ..registerFactory(() => GetAudioOutput(sl()))
    ..registerFactory(() => AudioOutputCubit(sl()))
    ..registerLazySingleton<PlayerStyleRepository>(
      PrefsPlayerStyleRepository.new,
    )
    ..registerFactory(() => LoadPlayerStyle(sl()))
    ..registerFactory(() => SavePlayerStyle(sl()))
    ..registerFactory(() => PlayerStyleCubit(loadStyle: sl(), saveStyle: sl()));
}
