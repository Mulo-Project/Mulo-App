import '../entities/channel_hit.dart';

/// 키워드로 유튜브 채널을 찾는다. 찾지 못하면 예외를 던진다.
abstract interface class ChannelSearcher {
  Future<List<ChannelHit>> search(String query);
}
