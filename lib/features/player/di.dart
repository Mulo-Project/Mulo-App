import 'dart:io';

import 'package:get_it/get_it.dart';

import '../../core/platform/native_playback_channel.dart';

import 'data/datasources/audio_engine_source.dart';
import 'data/datasources/audio_output_source.dart';
import 'data/repositories/just_audio_player_repository.dart';
import 'data/repositories/native_audio_player_repository.dart';
import 'data/repositories/platform_audio_output_repository.dart';
import 'data/repositories/prefs_player_style_repository.dart';
import 'domain/repositories/audio_output_repository.dart';
import 'domain/repositories/audio_player_repository.dart';
import 'domain/usecases/audio_playback_usecases.dart';
import 'domain/repositories/player_style_repository.dart';
import 'domain/usecases/get_audio_output.dart';
import 'domain/usecases/player_style_usecases.dart';
import 'presentation/bloc/audio_output_cubit.dart';
import 'presentation/bloc/now_playing_cubit.dart';
import 'presentation/bloc/player_style_cubit.dart';

void registerPlayer(GetIt sl) {
  sl
    ..registerLazySingleton(NativePlaybackChannel.new)
    ..registerLazySingleton<AudioEngineSource>(JustAudioEngineSource.new)
    // Android는 네이티브 서비스(ExoPlayer)가 소리를 내고, 그 밖의 OS는 just_audio.
    ..registerLazySingleton<AudioPlayerRepository>(
      () => Platform.isAndroid
          ? NativeAudioPlayerRepository(sl())
          : JustAudioPlayerRepository(sl()),
    )
    ..registerFactory(
      () => AudioPlayback(
        watchPosition: WatchAudioPosition(sl()),
        watchTrackChange: WatchAudioTrackChange(sl()),
        watchEnded: WatchAudioEnded(sl()),
        watchPlaying: WatchAudioPlaying(sl()),
        watchOpenPlayer: WatchOpenPlayer(sl()),
        setQueue: SetAudioQueue(sl()),
        skipTo: SkipAudioTo(sl()),
        play: PlayAudio(sl()),
        pause: PauseAudio(sl()),
        seek: SeekAudio(sl()),
        restore: RestoreAudioQueue(sl()),
        takeOpenPlayerRequest: TakeOpenPlayerRequest(sl()),
      ),
    )
    ..registerFactory(() => NowPlayingCubit(audio: sl()))
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
