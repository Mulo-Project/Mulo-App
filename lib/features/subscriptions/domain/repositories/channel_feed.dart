import '../entities/feed_video.dart';

/// 채널의 최근 영상 피드 (유튜브 채널 RSS). 읽지 못하면 예외를 던진다.
abstract interface class ChannelFeed {
  /// 채널 주소에서 채널 id(`UC…`)를 알아낸다. 알 수 없으면 null.
  Future<String?> resolveChannelId(String channelUrl);

  /// 채널의 최근 영상 (보통 15개).
  Future<List<FeedVideo>> fetch(String channelId);
}
