import '../entities/subscribed_channel.dart';
import '../entities/subscription_settings.dart';

/// 알림 글 (기기 언어로 만들어 넘긴다). 본문의 `%CHANNELS%` · `%COUNT%`는 새 영상을 찾았을 때 채워진다.
class BackgroundTexts {
  const BackgroundTexts({
    required this.channelName,
    required this.title,
    required this.body,
  });

  /// 알림 채널 이름.
  final String channelName;
  final String title;
  final String body;
}

/// 앱이 꺼져 있어도 새 영상을 확인하고 알리는 일 (Android WorkManager). 다른 OS는 아무것도 하지 않는다.
abstract interface class BackgroundChecker {
  /// 구독 채널 · 설정을 반영해 주기 확인을 예약하거나 (꺼져 있거나 켜 둔 채널이 없으면) 취소한다.
  Future<void> sync(
    List<SubscribedChannel> channels,
    SubscriptionSettings settings,
    BackgroundTexts texts,
  );

  /// 새 영상 알림을 눌러 앱이 열렸는지 (한 번 가져가면 비운다).
  Future<bool> takeOpenRequest();

  /// 앱이 켜져 있는 동안 새 영상 알림을 눌렀을 때.
  Stream<void> watchOpenRequests();

  /// 떠 있는 새 영상 알림을 걷는다.
  Future<void> clearNotification();

  /// 샘플 내용의 새 영상 알림을 지금 띄운다 (알림 모양 확인용 임시 기능).
  Future<void> showTestNotification();
}
