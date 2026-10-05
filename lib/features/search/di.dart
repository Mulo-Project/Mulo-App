import 'dart:io';

import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import 'data/engine/local_engine.dart';
import 'data/engine/routing_engine.dart';
import 'data/engine/server_engine.dart';
import 'domain/repositories/downloader_engine.dart';
import 'domain/usecases/search_usecases.dart';
import 'presentation/bloc/search_cubit.dart';

/// 검색 · 곡 정보 의존성. 데스크톱은 로컬 yt-dlp를 먼저 시도하고, 없으면 서버.
void registerSearch(GetIt sl) {
  sl
    ..registerLazySingleton<DownloaderEngine>(
      () => RoutingDownloaderEngine(
        local: Platform.isWindows || Platform.isLinux || Platform.isMacOS
            ? LocalEngine()
            : null,
        server: AppConfig.hasApiBaseUrl
            ? ServerEngine(baseUrl: AppConfig.apiBaseUrl)
            : null,
      ),
    )
    ..registerFactory(() => SearchTracks(sl()))
    ..registerFactory(() => FetchMediaInfo(sl()))
    ..registerFactory(() => SearchCubit(sl(), sl()));
}
