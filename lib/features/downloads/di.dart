import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../engine/data/engine_updater.dart';
import '../engine/data/native_yt_dlp.dart';

import 'data/repositories/native_download_queue_repository.dart';
import 'data/repositories/prefs_download_settings_repository.dart';
import 'data/repositories/native_video_save_repository.dart';
import '../library/domain/repositories/library_repository.dart';
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
    ..registerLazySingleton<DownloadQueueRepository>(
      // 받기 큐 · 이어받기 · 변환 · 태그 · 저장 · 보관함 등록은 네이티브가 한다 (D-167).
      () => NativeDownloadQueueRepository(
        settings: sl(),
        openLibrary: () => sl<LibraryRepository>().watchTracks().first,
        onEngineError: sl<EngineUpdater>().onDownloadFailed,
        onLibraryChanged: () {
          final db = sl<AppDatabase>();
          db.markTablesUpdated([
            db.tracks,
            db.playlistTracks,
            db.covers,
            db.coverColors,
            db.lyricsFiles,
          ]);
        },
      ),
    )
    ..registerLazySingleton<VideoSaveRepository>(
      () => NativeVideoSaveRepository(sl<NativeYtDlp>()),
    )
    ..registerFactory(() => IsVideoSaveAvailable(sl()))
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
    ..registerFactory(() => GetTrackSourceUrl(sl()))
    ..registerFactory(() => WatchTagNotices(sl()))
    ..registerFactory(() => PauseDownload(sl()))
    ..registerFactory(() => ResumeDownload(sl()))
    ..registerFactory(() => RetryDownload(sl()))
    ..registerFactory(() => CancelDownload(sl()))
    ..registerFactory(() => CancelAllDownloads(sl()))
    ..registerFactory(
      () => DownloadQueueCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    );
}
