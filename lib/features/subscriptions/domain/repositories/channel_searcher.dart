import '../entities/channel_details.dart';
import '../entities/channel_hit.dart';

/// 키워드로 유튜브 채널을 찾는다. 찾지 못하면 예외를 던진다.
abstract interface class ChannelSearcher {
  Future<List<ChannelHit>> search(String query);

  /// 채널 상세(배너 · 구독자 수). 못 읽으면 예외를 던진다.
  Future<ChannelDetails> details(String channelId);
}
