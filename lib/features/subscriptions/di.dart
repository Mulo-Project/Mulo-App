import 'dart:io';

import 'package:get_it/get_it.dart';

import '../notifications/data/datasources/notification_texts.dart';
import 'data/datasources/youtube_feed_client.dart';
import 'data/repositories/native_background_checker.dart';
import 'data/repositories/prefs_subscription_repository.dart';
import 'domain/repositories/background_checker.dart';
import 'domain/repositories/channel_feed.dart';
import 'domain/repositories/subscription_repository.dart';
import 'domain/usecases/subscription_usecases.dart';
import 'presentation/bloc/new_videos_cubit.dart';
import 'presentation/bloc/subscriptions_cubit.dart';

/// 채널 구독 · 새 영상 의존성. 구독 목록 cubit은 앱 전체에서 하나만 쓴다 (상세 화면의 구독 버튼 · 설정 · 새 영상 화면이 같이 본다).
void registerSubscriptions(GetIt sl) {
  sl
    ..registerLazySingleton<SubscriptionRepository>(
      PrefsSubscriptionRepository.new,
    )
    ..registerLazySingleton<ChannelFeed>(YoutubeFeedClient.new)
    ..registerLazySingleton<BackgroundChecker>(
      () => Platform.isAndroid
          ? NativeBackgroundChecker()
          : const NoBackgroundChecker(),
    )
    ..registerFactory(() => LoadSubscribedChannels(sl()))
    ..registerFactory(() => SaveSubscribedChannels(sl()))
    ..registerFactory(() => LoadSubscriptionSettings(sl()))
    ..registerFactory(() => SaveSubscriptionSettings(sl()))
    ..registerFactory(() => CreateSubscription(sl()))
    ..registerFactory(() => CheckNewVideos(sl()))
    ..registerFactory(() => SyncBackgroundCheck(sl()))
    ..registerFactory(() => TakeNewVideosOpen(sl()))
    ..registerFactory(() => WatchNewVideosOpens(sl()))
    ..registerFactory(() => ClearNewVideosNotification(sl()))
    ..registerLazySingleton(
      () => SubscriptionsCubit(
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        _backgroundTexts,
      ),
    )
    ..registerLazySingleton(
      () => NewVideosCubit(sl(), sl(), sl(), sl(), sl(), sl()),
    );
}

/// 백그라운드 알림 글: 기기 언어를 따른다 (화면이 없는 곳에서 만들어야 해서).
BackgroundTexts _backgroundTexts() {
  final l10n = systemL10n();
  return BackgroundTexts(
    channelName: l10n.notifChannelNewVideos,
    title: l10n.notifNewVideosTitle,
    body: l10n.notifNewVideosBody('%CHANNELS%', '%COUNT%'),
  );
}
