import 'package:get_it/get_it.dart';

import '../../core/platform/native_playback_channel.dart';
import 'data/datasources/audio_output_source.dart';
import 'data/repositories/native_audio_player_repository.dart';
import 'data/repositories/platform_audio_output_repository.dart';
import 'data/repositories/native_stop_log_repository.dart';
import 'data/repositories/prefs_mix_with_others_repository.dart';
import 'data/repositories/prefs_output_behavior_repository.dart';
import 'data/repositories/prefs_player_style_repository.dart';
import 'data/repositories/prefs_playback_speed_repository.dart';
import 'domain/repositories/audio_output_repository.dart';
import 'domain/repositories/audio_player_repository.dart';
import 'domain/usecases/audio_playback_usecases.dart';
import 'domain/repositories/mix_with_others_repository.dart';
import 'domain/repositories/output_behavior_repository.dart';
import 'domain/repositories/player_style_repository.dart';
import 'domain/repositories/stop_log_repository.dart';
import 'domain/usecases/stop_log_usecases.dart';
import 'presentation/bloc/stop_log_cubit.dart';
import 'domain/repositories/playback_speed_repository.dart';
import 'domain/usecases/playback_speed_usecases.dart';
import 'domain/usecases/get_audio_output.dart';
import 'domain/usecases/mix_with_others_usecases.dart';
import 'domain/usecases/output_behavior_usecases.dart';
import 'domain/usecases/player_style_usecases.dart';
import 'presentation/bloc/audio_output_cubit.dart';
import 'presentation/bloc/mix_with_others_cubit.dart';
import 'presentation/bloc/output_behavior_cubit.dart';
import 'presentation/bloc/now_playing_cubit.dart';
import 'presentation/bloc/player_style_cubit.dart';
import 'presentation/bloc/playback_speed_cubit.dart';

void registerPlayer(GetIt sl) {
  sl
    ..registerLazySingleton(NativePlaybackChannel.new)
    // 소리는 네이티브 서비스(ExoPlayer)가 낸다 (Android만 지원한다).
    ..registerLazySingleton<AudioPlayerRepository>(
      () => NativeAudioPlayerRepository(sl()),
    )
    ..registerFactory(
      () => AudioPlayback(
        watchPosition: WatchAudioPosition(sl()),
        watchTrackChange: WatchAudioTrackChange(sl()),
        watchEnded: WatchAudioEnded(sl()),
        watchPlaying: WatchAudioPlaying(sl()),
        watchOpenPlayer: WatchOpenPlayer(sl()),
        watchQueue: WatchAudioQueue(sl()),
        playNext: PlayAudioNext(sl()),
        addToQueue: AddAudioToQueue(sl()),
        removeFromQueue: RemoveAudioFromQueue(sl()),
        moveInQueue: MoveAudioInQueue(sl()),
        setShuffle: SetAudioShuffle(sl()),
        setRepeat: SetAudioRepeat(sl()),
        setQueue: SetAudioQueue(sl()),
        skipTo: SkipAudioTo(sl()),
        play: PlayAudio(sl()),
        pause: PauseAudio(sl()),
        seek: SeekAudio(sl()),
        setLoop: SetAudioLoop(sl()),
        restore: RestoreAudioQueue(sl()),
        takeOpenPlayerRequest: TakeOpenPlayerRequest(sl()),
      ),
    )
    ..registerFactory(() => NowPlayingCubit(audio: sl()))
    ..registerLazySingleton<StopLogRepository>(
      () => NativeStopLogRepository(sl()),
    )
    ..registerFactory(
      () => StopLogCubit(getLog: GetStopLog(sl()), clearLog: ClearStopLog(sl())),
    )
    ..registerLazySingleton(AudioOutputSource.new)
    ..registerLazySingleton<AudioOutputRepository>(
      () => PlatformAudioOutputRepository(sl()),
    )
    ..registerFactory(() => GetAudioOutput(sl()))
    ..registerFactory(() => AudioOutputCubit(sl(), sl()))
    ..registerFactory(() => WatchAudioOutputChanges(sl()))
    ..registerLazySingleton<PlayerStyleRepository>(
      PrefsPlayerStyleRepository.new,
    )
    ..registerFactory(() => LoadPlayerStyle(sl()))
    ..registerFactory(() => SavePlayerStyle(sl()))
    ..registerFactory(() => PlayerStyleCubit(loadStyle: sl(), saveStyle: sl()))
    ..registerLazySingleton<MixWithOthersRepository>(
      () => PrefsMixWithOthersRepository(sl()),
    )
    ..registerFactory(() => LoadMixWithOthers(sl()))
    ..registerFactory(() => SaveMixWithOthers(sl()))
    ..registerFactory(() => MixWithOthersCubit(loadMix: sl(), saveMix: sl()))
    ..registerLazySingleton<PlaybackSpeedRepository>(
      () => PrefsPlaybackSpeedRepository(sl()),
    )
    ..registerFactory(() => LoadPlaybackSpeed(sl()))
    ..registerFactory(() => SavePlaybackSpeed(sl()))
    ..registerFactory(
      () => PlaybackSpeedCubit(loadSpeed: sl(), saveSpeed: sl()),
    )
    ..registerLazySingleton<OutputBehaviorRepository>(
      () => PrefsOutputBehaviorRepository(sl()),
    )
    ..registerFactory(() => LoadOutputBehavior(sl()))
    ..registerFactory(() => SaveOutputBehavior(sl()))
    ..registerFactory(
      () => OutputBehaviorCubit(loadBehavior: sl(), saveBehavior: sl()),
    );
}
