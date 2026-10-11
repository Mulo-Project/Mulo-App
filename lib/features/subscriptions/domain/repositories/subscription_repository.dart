import '../entities/subscribed_channel.dart';
import '../entities/subscription_settings.dart';

/// 구독 채널 목록 · 확인 설정 저장소.
abstract interface class SubscriptionRepository {
  Future<List<SubscribedChannel>> loadChannels();
  Future<void> saveChannels(List<SubscribedChannel> channels);
  Future<SubscriptionSettings> loadSettings();
  Future<void> saveSettings(SubscriptionSettings settings);
}
