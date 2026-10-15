import '../entities/background_status.dart';
import '../entities/new_video_download_request.dart';
import '../entities/subscribed_channel.dart';
import '../entities/subscription_settings.dart';

/// 알림 글 (기기 언어로 만들어 넘긴다). 영상이 여럿일 때 묶음 알림의 본문 `%CHANNELS%` · `%COUNT%`는 새 영상을 찾았을 때 채워진다.
class BackgroundTexts {
  const BackgroundTexts({
    required this.channelName,
    required this.title,
    required this.body,
    required this.downloadLabel,
    required this.cancelLabel,
  });

  /// 알림 채널 이름.
  final String channelName;
  final String title;
  final String body;

  /// 영상 알림의 버튼 글자: 바로 받기 · 취소.
  final String downloadLabel;
  final String cancelLabel;
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

  /// 알림의 "바로 받기"로 들어온, 아직 처리하지 않은 받기 요청 (가져가면 비운다).
  Future<List<NewVideoDownloadRequest>> takeDownloadRequests();

  /// 앱이 켜져 있는 동안 알림의 "바로 받기"를 눌렀을 때.
  Stream<NewVideoDownloadRequest> watchDownloadRequests();

  /// 앱을 뒤로 보낸다 (알림 버튼으로 켜진 앱이 받기를 시작한 뒤).
  Future<void> moveAppToBack();

  /// 떠 있는 새 영상 알림을 걷는다.
  Future<void> clearNotification();

  /// 주기를 기다리지 않고 지금 한 번 확인한다 (끝나면 [status]의 마지막 확인 시각이 바뀐다).
  Future<void> checkNow();

  /// 예약 · 알림 막힘 · 마지막 확인 결과. 알 수 없으면 null.
  Future<BackgroundStatus?> status();

  /// 샘플 내용의 새 영상 알림을 지금 띄운다 (알림 모양 확인용 임시 기능).
  Future<void> showTestNotification();
}
