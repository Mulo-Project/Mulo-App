import 'package:get_it/get_it.dart';

import 'package:path_provider/path_provider.dart';

import 'data/datasources/audio_file_downloader.dart';
import 'data/datasources/downloaded_file_store.dart';
import 'data/repositories/engine_download_queue_repository.dart';
import 'data/repositories/prefs_download_settings_repository.dart';
import 'domain/repositories/download_queue_repository.dart';
import 'domain/repositories/download_settings_repository.dart';
import 'domain/usecases/download_usecases.dart';
import 'presentation/bloc/download_queue_cubit.dart';
import 'presentation/bloc/download_settings_cubit.dart';

/// 다운로드 대기열 의존성.
void registerDownloads(GetIt sl) {
  sl
    ..registerLazySingleton<AudioFileDownloader>(HttpAudioFileDownloader.new)
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
        tempDir: getTemporaryDirectory,
      ),
    )
    ..registerLazySingleton<DownloadSettingsRepository>(
      PrefsDownloadSettingsRepository.new,
    )
    ..registerFactory(() => GetSelectableFormats(sl()))
    ..registerFactory(() => LoadSavePath(sl()))
    ..registerFactory(() => SaveSavePath(sl()))
    ..registerFactory(() => PickSaveFolder(sl()))
    ..registerFactory(() => DownloadSettingsCubit(sl(), sl(), sl()))
    ..registerFactory(() => WatchDownloadQueue(sl()))
    ..registerFactory(() => EnqueueDownload(sl()))
    ..registerFactory(() => PauseDownload(sl()))
    ..registerFactory(() => ResumeDownload(sl()))
    ..registerFactory(() => RetryDownload(sl()))
    ..registerFactory(() => CancelDownload(sl()))
    ..registerFactory(
      () => DownloadQueueCubit(sl(), sl(), sl(), sl(), sl(), sl()),
    );
}
