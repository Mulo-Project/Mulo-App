import 'package:get_it/get_it.dart';

import 'data/repositories/sample_download_queue_repository.dart';
import 'domain/repositories/download_queue_repository.dart';
import 'domain/usecases/download_usecases.dart';
import 'presentation/bloc/download_queue_cubit.dart';

/// 다운로드 대기열 의존성.
void registerDownloads(GetIt sl) {
  sl
    ..registerLazySingleton<DownloadQueueRepository>(
      () => SampleDownloadQueueRepository(),
    )
    ..registerFactory(() => WatchDownloadQueue(sl()))
    ..registerFactory(() => EnqueueDownload(sl()))
    ..registerFactory(() => PauseDownload(sl()))
    ..registerFactory(() => ResumeDownload(sl()))
    ..registerFactory(() => CancelDownload(sl()))
    ..registerFactory(() => DownloadQueueCubit(sl(), sl(), sl(), sl(), sl()));
}
