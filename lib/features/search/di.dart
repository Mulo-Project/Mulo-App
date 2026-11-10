import 'dart:io';

import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../engine/data/android_yt_dlp.dart';
import '../engine/data/yt_dlp_manager.dart';
import 'data/datasources/native_preview_player.dart';
import 'data/datasources/url_launcher_link_opener.dart';
import 'data/engine/cached_engine.dart';
import 'data/repositories/prefs_video_quality_repository.dart';
import 'data/engine/explode_engine.dart';
import 'data/engine/local_engine.dart';
import 'data/engine/routing_engine.dart';
import 'data/engine/soundcloud_avatar_engine.dart';
import 'data/engine/server_engine.dart';
import 'domain/repositories/downloader_engine.dart';
import 'domain/repositories/link_opener.dart';
import 'domain/repositories/preview_player.dart';
import 'domain/repositories/video_quality_repository.dart';
import 'domain/usecases/search_usecases.dart';
import 'presentation/bloc/audio_language_cubit.dart';
import 'presentation/bloc/preview_cubit.dart';
import 'presentation/bloc/preview_video_cubit.dart';
import 'presentation/bloc/search_cubit.dart';
import 'presentation/bloc/media_hit_memo.dart';
import 'presentation/bloc/saved_videos_cubit.dart';
import 'presentation/bloc/stream_cache_cubit.dart';
import 'data/repositories/prefs_saved_video_repository.dart';
import 'domain/repositories/saved_video_repository.dart';
import 'domain/usecases/saved_video_usecases.dart';
import 'presentation/bloc/video_quality_cubit.dart';

/// 검색 · 곡 정보 의존성. 로컬 yt-dlp(데스크톱 · Android full)를 먼저 시도하고, 없으면 서버.
void registerSearch(GetIt sl) {
  sl
    ..registerLazySingleton<DownloaderEngine>(
      () => CachedDownloaderEngine(
        infoTtl: const Duration(hours: 6),
        SoundcloudAvatarEngine(
          YoutubeExplodeEngine(
            RoutingDownloaderEngine(
              local: Platform.isAndroid
                  ? LocalEngine(run: sl<AndroidYtDlp>().run)
                  : Platform.isWindows || Platform.isLinux || Platform.isMacOS
                  ? LocalEngine(
                      resolveExecutable: sl<YtDlpManager>().executablePath,
                    )
                  : null,
              server: AppConfig.hasApiBaseUrl
                  ? ServerEngine(baseUrl: AppConfig.apiBaseUrl)
                  : null,
            ),
          ),
        ),
      ),
    )
    ..registerLazySingleton<LinkOpener>(UrlLauncherLinkOpener.new)
    ..registerFactory(() => SearchTracks(sl()))
    ..registerFactory(() => FetchMediaInfo(sl()))
    ..registerFactory(() => FetchSubtitles(sl()))
    ..registerFactory(() => SearchPlaylists(sl()))
    ..registerFactory(() => FetchChannelInfo(sl()))
    ..registerFactory(() => OpenLink(sl()))
    ..registerLazySingleton<PreviewPlayer>(NativePreviewPlayer.new)
    ..registerLazySingleton(MediaHitMemo.new)
    ..registerFactory(() => ResolveAudioStream(sl(), sl()))
    ..registerLazySingleton<VideoQualityRepository>(
      PrefsVideoQualityRepository.new,
    )
    ..registerFactory(() => LoadAutoVideoQuality(sl()))
    ..registerFactory(() => SaveAutoVideoQuality(sl()))
    ..registerFactory(() => LoadVideoQuality(sl()))
    ..registerFactory(() => SaveVideoQuality(sl()))
    ..registerFactory(() => VideoQualityCubit(sl(), sl()))
    ..registerFactory(() => ResolveVideoStream(sl(), sl(), sl()))
    ..registerFactory(() => PlayPreviewVideo(sl()))
    ..registerFactory(() => PreviewVideoCubit(sl(), sl()))
    ..registerFactory(() => EnterPictureInPicture(sl()))
    ..registerFactory(() => FetchAudioLanguages(sl()))
    ..registerFactory(() => AudioLanguageCubit(sl()))
    ..registerFactory(() => PlayPreview(sl()))
    ..registerFactory(() => RememberPreview(sl()))
    ..registerFactory(() => CurrentPreview(sl()))
    ..registerFactory(() => SeekPreview(sl()))
    ..registerFactory(() => PausePreview(sl()))
    ..registerFactory(() => ResumePreview(sl()))
    ..registerFactory(() => StopPreview(sl()))
    ..registerFactory(() => WatchPreviewCompleted(sl()))
    ..registerFactory(() => WatchPreviewProgress(sl()))
    ..registerFactory(() => WatchPreviewFailures(sl()))
    ..registerFactory(() => GetStreamCacheInfo(sl()))
    ..registerFactory(() => ClearStreamCache(sl()))
    ..registerFactory(() => SetStreamCacheLimit(sl()))
    ..registerFactory(() => StreamCacheCubit(sl(), sl(), sl()))
    ..registerLazySingleton<SavedVideoRepository>(PrefsSavedVideoRepository.new)
    ..registerFactory(() => LoadSavedVideos(sl(), sl()))
    ..registerFactory(() => SaveVideo(sl(), sl(), sl(), sl()))
    ..registerFactory(() => RemoveSavedVideo(sl(), sl()))
    ..registerFactory(() => MarkSavedVideoReady(sl()))
    ..registerFactory(() => ResumeSavedVideos(sl(), sl(), sl(), sl()))
    ..registerFactory(() => WatchSavedDone(sl()))
    ..registerFactory(() => WatchSavedProgress(sl()))
    ..registerFactory(
      () => SavedVideosCubit(
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        resume: sl(),
        watchProgress: sl<WatchSavedProgress>(),
      ),
    )
    ..registerFactory(
      () => PreviewCubit(
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        resolveVideo: sl(),
        enterPictureInPicture: sl(),
        loadAutoQuality: sl(),
        saveAutoQuality: sl(),
      ),
    )
    ..registerFactory(() => SearchCubit(sl(), sl()));
}
