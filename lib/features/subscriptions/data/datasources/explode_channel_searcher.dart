import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../domain/entities/channel_details.dart';
import '../../domain/entities/channel_hit.dart';
import '../../domain/repositories/channel_searcher.dart';

/// `youtube_explode_dart`의 채널 검색 필터로 채널을 찾는다 (키 · 서버 불필요).
class ExplodeChannelSearcher implements ChannelSearcher {
  @override
  Future<List<ChannelHit>> search(String query) async {
    final yt = YoutubeExplode();
    try {
      final list = await yt.search.searchContent(
        query,
        filter: TypeFilters.channel,
      );
      return [
        for (final r in list)
          if (r is SearchChannel)
            ChannelHit(
              id: r.id.value,
              name: r.name,
              description: r.description,
              thumbnailUrl: _thumbnail(r.thumbnails),
              videoCount: r.videoCount,
            ),
      ];
    } finally {
      yt.close();
    }
  }

  @override
  Future<ChannelDetails> details(String channelId) async {
    final yt = YoutubeExplode();
    try {
      final c = await yt.channels.get(channelId);
      return ChannelDetails(
        bannerUrl: c.bannerUrl.isEmpty ? null : c.bannerUrl,
        logoUrl: c.logoUrl.isEmpty ? null : c.logoUrl,
        subscriberCount: c.subscribersCount,
      );
    } finally {
      yt.close();
    }
  }

  /// 가장 큰 이미지. 주소가 `//`로 시작하면 https를 붙인다.
  static String? _thumbnail(List<Thumbnail> thumbnails) {
    if (thumbnails.isEmpty) return null;
    final url = thumbnails.last.url;
    return url.hasScheme ? url.toString() : 'https:$url';
  }
}
