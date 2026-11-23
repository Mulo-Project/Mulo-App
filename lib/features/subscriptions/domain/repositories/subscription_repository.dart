import '../entities/subscribed_channel.dart';
import '../entities/subscription_settings.dart';

/// 구독 채널 목록 · 확인 설정 저장소.
abstract interface class SubscriptionRepository {
  Future<List<SubscribedChannel>> loadChannels();
  Future<void> saveChannels(List<SubscribedChannel> channels);
  Future<SubscriptionSettings> loadSettings();
  Future<void> saveSettings(SubscriptionSettings settings);

  /// 이미 한 번 안내했거나 새 영상 화면에서 본 영상 id (앱을 켤 때 같은 영상을 또 알리지 않으려고).
  Future<Set<String>> loadSeenVideos();
  Future<void> saveSeenVideos(Set<String> ids);
}
