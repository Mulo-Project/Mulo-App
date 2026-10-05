import 'dart:io';

import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../engine/data/android_yt_dlp.dart';
import '../engine/data/yt_dlp_manager.dart';
import 'data/datasources/url_launcher_link_opener.dart';
import 'data/engine/local_engine.dart';
import 'data/engine/routing_engine.dart';
import 'data/engine/server_engine.dart';
import 'domain/repositories/downloader_engine.dart';
import 'domain/repositories/link_opener.dart';
import 'domain/usecases/search_usecases.dart';
import 'presentation/bloc/search_cubit.dart';

/// 검색 · 곡 정보 의존성. 로컬 yt-dlp(데스크톱 · Android full)를 먼저 시도하고, 없으면 서버.
void registerSearch(GetIt sl) {
  sl
    ..registerLazySingleton<DownloaderEngine>(
      () => RoutingDownloaderEngine(
        local: Platform.isAndroid
            ? LocalEngine(run: sl<AndroidYtDlp>().run)
            : Platform.isWindows || Platform.isLinux || Platform.isMacOS
            ? LocalEngine(resolveExecutable: sl<YtDlpManager>().executablePath)
            : null,
        server: AppConfig.hasApiBaseUrl
            ? ServerEngine(baseUrl: AppConfig.apiBaseUrl)
            : null,
      ),
    )
    ..registerLazySingleton<LinkOpener>(UrlLauncherLinkOpener.new)
    ..registerFactory(() => SearchTracks(sl()))
    ..registerFactory(() => FetchMediaInfo(sl()))
    ..registerFactory(() => FetchChannelInfo(sl()))
    ..registerFactory(() => OpenLink(sl()))
    ..registerFactory(() => SearchCubit(sl(), sl()));
}
