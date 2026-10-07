import 'dart:io';

import 'package:get_it/get_it.dart';

import 'data/repositories/audio_service_media_session.dart';
import 'data/repositories/local_download_notifier.dart';
import 'data/repositories/no_notification_repositories.dart';
import 'data/repositories/prefs_notification_settings_repository.dart';
import 'domain/repositories/download_notifier.dart';
import 'domain/repositories/media_session.dart';
import 'domain/repositories/notification_settings_repository.dart';
import 'domain/usecases/notification_usecases.dart';
import 'presentation/bloc/notification_settings_cubit.dart';
import 'presentation/bloc/notification_sync_cubit.dart';

/// 알림 (받기 진행 · 결과, 재생 알림) 의존성. 알림창 구현은 Android만 있고 다른 OS는 아무것도 띄우지 않는다.
void registerNotifications(GetIt sl) {
  sl
    ..registerLazySingleton<NotificationSettingsRepository>(
      PrefsNotificationSettingsRepository.new,
    )
    ..registerLazySingleton<DownloadNotifier>(
      () => Platform.isAndroid ? LocalDownloadNotifier() : NoDownloadNotifier(),
    )
    ..registerLazySingleton<MediaSession>(
      () => Platform.isAndroid ? AudioServiceMediaSession() : NoMediaSession(),
    )
    ..registerFactory(() => LoadNotificationSettings(sl()))
    ..registerFactory(() => SaveNotificationSettings(sl()))
    ..registerFactory(() => IsNotificationPermissionGranted(sl()))
    ..registerFactory(() => RequestNotificationPermission(sl()))
    ..registerFactory(() => OpenNotificationSystemSettings(sl()))
    ..registerFactory(
      () => NotificationActions(
        showProgress: ShowDownloadProgress(sl()),
        clearProgress: ClearDownloadProgress(sl()),
        showResult: ShowDownloadResult(sl()),
        clearResults: ClearDownloadResults(sl()),
        watchCommands: WatchMediaCommands(sl()),
        watchDownloadActions: WatchDownloadActions(sl()),
        updateSession: UpdateMediaSession(sl()),
        isPermissionGranted: IsNotificationPermissionGranted(sl()),
        requestPermission: RequestNotificationPermission(sl()),
      ),
    )
    ..registerFactory(
      () => NotificationSettingsCubit(
        load: sl(),
        save: sl(),
        isGranted: sl(),
        request: sl(),
        openSystemSettings: sl(),
      ),
    )
    ..registerFactory(() => NotificationSyncCubit(sl()));
}
