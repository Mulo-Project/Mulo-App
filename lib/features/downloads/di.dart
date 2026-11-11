import 'package:get_it/get_it.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../engine/data/android_yt_dlp.dart';

import 'data/datasources/audio_file_downloader.dart';
import 'data/datasources/audio_transcoder.dart';
import 'data/datasources/cover_tag_writer.dart';
import 'data/datasources/ffmpeg_tag_writer.dart';
import 'data/datasources/download_queue_store.dart';
import 'data/datasources/downloaded_file_store.dart';
import 'data/repositories/engine_download_queue_repository.dart';
import 'data/repositories/prefs_download_settings_repository.dart';
import 'data/repositories/yt_dlp_video_save_repository.dart';
import 'domain/repositories/video_save_repository.dart';
import 'domain/repositories/download_queue_repository.dart';
import 'domain/repositories/download_settings_repository.dart';
import 'domain/usecases/download_usecases.dart';
import 'presentation/bloc/download_preferences_cubit.dart';
import 'presentation/bloc/download_queue_cubit.dart';
import 'presentation/bloc/subtitle_availability_cubit.dart';
import 'presentation/bloc/subtitle_preview_cubit.dart';
import 'presentation/bloc/download_settings_cubit.dart';

/// 다운로드 대기열 의존성.
void registerDownloads(GetIt sl) {
  sl
    ..registerLazySingleton<AudioFileDownloader>(HttpAudioFileDownloader.new)
    ..registerLazySingleton<AudioTranscoder>(PlatformAudioTranscoder.new)
    ..registerLazySingleton<DownloadQueueStore>(PrefsDownloadQueueStore.new)
    ..registerLazySingleton<DownloadedFileStore>(
      PlatformDownloadedFileStore.new,
    )
    ..registerLazySingleton<DownloadQueueRepository>(
      () => EngineDownloadQueueRepository(
        engine: sl(),
        downloader: sl(),
        store: sl(),
        library: sl(),
        playlists: sl(),
        covers: sl(),
        colors: sl(),
        settings: sl(),
        transcoder: sl(),
        coverTags: const CoverTagWriter(ffmpeg: FfmpegTagWriter()),
        lyrics: sl(),
        queueStore: sl(),
        // 받다 만 파일은 앱을 껐다 켜도 남아야 해서 캐시가 아닌 앱 전용 폴더에 둔다.
        tempDir: _partsDirectory,
      ),
    )
    ..registerLazySingleton<VideoSaveRepository>(
      () => YtDlpVideoSaveRepository(
        run: sl<AndroidYtDlp>().run,
        available: sl<AndroidYtDlp>().isAvailable,
        store: sl(),
        tempDir: () => Directory(
          '${Directory.systemTemp.path}${Platform.pathSeparator}mulo_video',
        ).create(recursive: true),
      ),
    )
    ..registerFactory(() => IsVideoSaveAvailable(sl()))
    ..registerFactory(() => SaveVideoFile(sl()))
    ..registerLazySingleton<DownloadSettingsRepository>(
      PrefsDownloadSettingsRepository.new,
    )
    ..registerFactory(() => SubtitleAvailabilityCubit(sl()))
    ..registerFactory(() => SubtitlePreviewCubit(sl()))
    ..registerFactory(() => GetSelectableFormats(sl()))
    ..registerFactory(() => LoadSavePath(sl()))
    ..registerFactory(() => SaveSavePath(sl()))
    ..registerFactory(() => LoadFixedSavePath(sl()))
    ..registerFactory(() => ClearSavePath(sl()))
    ..registerFactory(() => PickSaveFolder(sl()))
    ..registerFactory(() => DownloadSettingsCubit(sl(), sl(), sl(), sl(), sl()))
    ..registerFactory(() => LoadDownloadPreferences(sl()))
    ..registerFactory(() => SaveDownloadFormat(sl()))
    ..registerFactory(() => DownloadPreferencesCubit(sl(), sl()))
    ..registerFactory(() => WatchDownloadQueue(sl()))
    ..registerFactory(() => EnqueueDownload(sl()))
    ..registerFactory(() => FindExistingDownload(sl()))
    ..registerFactory(() => WatchDownloadedKeys(sl()))
    ..registerFactory(() => GetTrackSourceUrl(sl()))
    ..registerFactory(() => WatchTagNotices(sl()))
    ..registerFactory(() => PauseDownload(sl()))
    ..registerFactory(() => ResumeDownload(sl()))
    ..registerFactory(() => RetryDownload(sl()))
    ..registerFactory(() => CancelDownload(sl()))
    ..registerFactory(() => CancelAllDownloads(sl()))
    ..registerFactory(
      () => DownloadQueueCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    );
}

Future<Directory> _partsDirectory() async => Directory(
  '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}download_parts',
);
