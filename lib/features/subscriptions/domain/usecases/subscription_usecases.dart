import '../../../../core/usecase/usecase.dart';
import '../entities/channel_new_videos.dart';
import '../entities/subscribed_channel.dart';
import '../entities/subscription_settings.dart';
import '../repositories/background_checker.dart';
import '../repositories/channel_feed.dart';
import '../repositories/subscription_repository.dart';

class LoadSubscribedChannels
    implements UseCase<List<SubscribedChannel>, NoParams> {
  const LoadSubscribedChannels(this._repo);

  final SubscriptionRepository _repo;

  @override
  Future<List<SubscribedChannel>> call(NoParams params) => _repo.loadChannels();
}

class SaveSubscribedChannels implements UseCase<void, List<SubscribedChannel>> {
  const SaveSubscribedChannels(this._repo);

  final SubscriptionRepository _repo;

  @override
  Future<void> call(List<SubscribedChannel> channels) =>
      _repo.saveChannels(channels);
}

class LoadSubscriptionSettings
    implements UseCase<SubscriptionSettings, NoParams> {
  const LoadSubscriptionSettings(this._repo);

  final SubscriptionRepository _repo;

  @override
  Future<SubscriptionSettings> call(NoParams params) => _repo.loadSettings();
}

class SaveSubscriptionSettings implements UseCase<void, SubscriptionSettings> {
  const SaveSubscriptionSettings(this._repo);

  final SubscriptionRepository _repo;

  @override
  Future<void> call(SubscriptionSettings settings) =>
      _repo.saveSettings(settings);
}

/// 구독하려는 채널 정보.
class SubscribeParams {
  const SubscribeParams({
    required this.channelUrl,
    required this.name,
    this.thumbnailUrl,
  });

  final String channelUrl;
  final String name;
  final String? thumbnailUrl;
}

/// 채널 주소에서 채널 id를 알아내 구독 채널을 만든다. 첫 구독이라 기준 시각은 지금이다
/// (기존 영상은 새 영상이 아니다). 채널 id를 알 수 없으면 null.
class CreateSubscription
    implements UseCase<SubscribedChannel?, SubscribeParams> {
  const CreateSubscription(this._feed, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ChannelFeed _feed;
  final DateTime Function() _now;

  @override
  Future<SubscribedChannel?> call(SubscribeParams params) async {
    final String? id;
    try {
      id = await _feed.resolveChannelId(params.channelUrl);
    } on Object {
      return null;
    }
    if (id == null) return null;
    return SubscribedChannel(
      id: id,
      name: params.name,
      url: params.channelUrl,
      thumbnailUrl: params.thumbnailUrl,
      baselineAt: _now().toUtc(),
    );
  }
}

/// 켜 둔 채널들의 새 영상을 확인한다. 읽지 못한 채널은 건너뛴다.
class CheckNewVideos
    implements UseCase<List<ChannelNewVideos>, List<SubscribedChannel>> {
  const CheckNewVideos(this._feed);

  final ChannelFeed _feed;

  @override
  Future<List<ChannelNewVideos>> call(List<SubscribedChannel> channels) async {
    final results = await Future.wait<ChannelNewVideos?>([
      for (final c in channels)
        if (c.enabled) _check(c),
    ]);
    return [for (final r in results) ?r];
  }

  Future<ChannelNewVideos?> _check(SubscribedChannel channel) async {
    try {
      final feed = await _feed.fetch(channel.id);
      final fresh = [
        for (final v in feed)
          if (v.publishedAt.isAfter(channel.baselineAt)) v,
      ]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      DateTime? latest;
      for (final v in feed) {
        if (latest == null || v.publishedAt.isAfter(latest)) {
          latest = v.publishedAt;
        }
      }
      return ChannelNewVideos(
        channel: channel,
        videos: fresh,
        latestPublishedAt: latest,
      );
    } on Object {
      return null;
    }
  }
}

/// 채널별로 "여기까지 봤다"고 표시해 기준 시각을 당긴다 (뒤로는 되돌리지 않는다).
List<SubscribedChannel> markSeenChannels(
  List<SubscribedChannel> channels,
  Map<String, DateTime> seenUntil,
) => [
  for (final c in channels)
    if (seenUntil[c.id] case final t? when t.isAfter(c.baselineAt))
      c.copyWith(baselineAt: t)
    else
      c,
];

class SyncBackgroundParams {
  const SyncBackgroundParams(this.channels, this.settings, this.texts);

  final List<SubscribedChannel> channels;
  final SubscriptionSettings settings;
  final BackgroundTexts texts;
}

class SyncBackgroundCheck implements UseCase<void, SyncBackgroundParams> {
  const SyncBackgroundCheck(this._checker);

  final BackgroundChecker _checker;

  @override
  Future<void> call(SyncBackgroundParams p) =>
      _checker.sync(p.channels, p.settings, p.texts);
}

class TakeNewVideosOpen implements UseCase<bool, NoParams> {
  const TakeNewVideosOpen(this._checker);

  final BackgroundChecker _checker;

  @override
  Future<bool> call(NoParams params) => _checker.takeOpenRequest();
}

class WatchNewVideosOpens implements StreamUseCase<void, NoParams> {
  const WatchNewVideosOpens(this._checker);

  final BackgroundChecker _checker;

  @override
  Stream<void> call(NoParams params) => _checker.watchOpenRequests();
}

class ClearNewVideosNotification implements UseCase<void, NoParams> {
  const ClearNewVideosNotification(this._checker);

  final BackgroundChecker _checker;

  @override
  Future<void> call(NoParams params) => _checker.clearNotification();
}
