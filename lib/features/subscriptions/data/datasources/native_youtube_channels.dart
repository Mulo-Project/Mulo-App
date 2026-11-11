import 'package:flutter/services.dart';

import '../../domain/entities/channel_details.dart';
import '../../domain/entities/channel_hit.dart';
import '../../domain/entities/feed_video.dart';
import '../../domain/repositories/channel_feed.dart';
import '../../domain/repositories/channel_searcher.dart';

/// 유튜브 채널 읽기(검색 · 상세 · 채널 id · 최근 영상)는 Android 네이티브(`YoutubeChannels` · `YoutubeBrowser`)가 한다.
/// Dart는 요청을 보내고 결과를 앱 모델로 바꾸기만 한다.
class NativeYoutubeChannels implements ChannelSearcher, ChannelFeed {
  NativeYoutubeChannels({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_app/youtube_resolve');

  final MethodChannel _channel;

  @override
  Future<List<ChannelHit>> search(String query) async {
    final items = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'searchChannels',
      {'query': query},
    );
    return [
      for (final m in items ?? const <Map<Object?, Object?>>[])
        ChannelHit(
          id: m['id']! as String,
          name: m['name'] as String? ?? '',
          description: m['description'] as String? ?? '',
          thumbnailUrl: m['thumbnail'] as String?,
          videoCount: (m['videoCount'] as num?)?.toInt(),
        ),
    ];
  }

  @override
  Future<ChannelDetails> details(String channelId) async {
    final m = await _channel.invokeMapMethod<Object?, Object?>(
      'channelDetails',
      {'channelId': channelId},
    );
    return ChannelDetails(
      bannerUrl: m?['bannerUrl'] as String?,
      logoUrl: m?['logoUrl'] as String?,
      subscriberCount: (m?['subscriberCount'] as num?)?.toInt(),
      description: m?['description'] as String?,
    );
  }

  @override
  Future<String?> resolveChannelId(String channelUrl) =>
      _channel.invokeMethod<String>('resolveChannelId', {'url': channelUrl});

  @override
  Future<List<FeedVideo>> fetch(String channelId) async {
    final items = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'channelFeed',
      {'channelId': channelId},
    );
    return [
      for (final m in items ?? const <Map<Object?, Object?>>[])
        FeedVideo(
          id: m['id']! as String,
          title: m['title'] as String? ?? '',
          publishedAt: DateTime.fromMillisecondsSinceEpoch(
            (m['publishedMs']! as num).toInt(),
            isUtc: true,
          ),
          author: m['author'] as String? ?? '',
          thumbnailUrl: m['thumbnail'] as String?,
          viewCount: (m['views'] as num?)?.toInt(),
        ),
    ];
  }
}
