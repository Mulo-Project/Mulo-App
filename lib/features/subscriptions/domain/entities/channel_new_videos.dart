import 'package:equatable/equatable.dart';

import 'feed_video.dart';
import 'subscribed_channel.dart';

/// 채널 하나를 확인한 결과: 기준 시각 이후의 새 영상 (최신 순)과 피드에서 가장 늦게 올라온 시각.
class ChannelNewVideos extends Equatable {
  const ChannelNewVideos({
    required this.channel,
    required this.videos,
    this.latestPublishedAt,
  });

  final SubscribedChannel channel;
  final List<FeedVideo> videos;

  /// 피드에서 가장 늦게 올라온 영상의 시각 (새 영상이 없어도 있을 수 있다). 확인함 표시에 쓴다.
  final DateTime? latestPublishedAt;

  @override
  List<Object?> get props => [channel, videos, latestPublishedAt];
}
