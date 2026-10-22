import '../../../../core/usecase/usecase.dart';
import '../entities/background_status.dart';
import '../entities/channel_details.dart';
import '../entities/channel_hit.dart';
import '../entities/channel_new_videos.dart';
import '../entities/new_video_download_request.dart';
import '../entities/subscribed_channel.dart';
import '../entities/subscription_settings.dart';
import '../repositories/background_checker.dart';
import '../repositories/channel_feed.dart';
import '../repositories/channel_searcher.dart';
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
    this.channelId,
    this.categories = const {},
    this.savePath = '',
  });

  /// 채널 검색 결과로 구독할 때: 채널 id를 이미 알고 있다.
  SubscribeParams.fromHit(
    ChannelHit hit, {
    this.categories = const {},
    this.savePath = '',
  }) : channelUrl = hit.url,
       name = hit.name,
       thumbnailUrl = hit.thumbnailUrl,
       channelId = hit.id;

  final String channelUrl;
  final String name;
  final String? thumbnailUrl;

  /// 알고 있으면 채널 페이지를 읽지 않는다.
  final String? channelId;

  /// 알림 · 새 영상에 넣을 분류 (비어 있으면 모든 분류).
  final Set<String> categories;

  /// 새 영상을 받아 저장할 폴더 (비어 있으면 기본 저장 위치).
  final String savePath;
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
      id = params.channelId ?? await _feed.resolveChannelId(params.channelUrl);
    } on Object {
      return null;
    }
    if (id == null) return null;
    return SubscribedChannel(
      id: id,
      name: params.name,
      url: params.channelUrl,
      thumbnailUrl: params.thumbnailUrl,
      categories: params.categories,
      savePath: params.savePath,
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

/// 백그라운드 확인을 지금 한 번 돌린다.
class CheckNewVideosNow implements UseCase<void, NoParams> {
  const CheckNewVideosNow(this._checker);

  final BackgroundChecker _checker;

  @override
  Future<void> call(NoParams params) => _checker.checkNow();
}

/// 백그라운드 확인 진단 정보 (마지막 확인 시각 · 알림 막힘 등).
class GetBackgroundStatus implements UseCase<BackgroundStatus?, NoParams> {
  const GetBackgroundStatus(this._checker);

  final BackgroundChecker _checker;

  @override
  Future<BackgroundStatus?> call(NoParams params) => _checker.status();
}

/// 키워드로 채널 찾기.
class SearchChannels implements UseCase<List<ChannelHit>, String> {
  const SearchChannels(this._searcher);

  final ChannelSearcher _searcher;

  @override
  Future<List<ChannelHit>> call(String query) => _searcher.search(query.trim());
}

/// 새 영상 알림을 지금 한 번 띄운다 (알림 모양 확인용 임시 기능).
class ShowTestNewVideosNotification implements UseCase<void, NoParams> {
  const ShowTestNewVideosNotification(this._checker);

  final BackgroundChecker _checker;

  @override
  Future<void> call(NoParams params) => _checker.showTestNotification();
}

/// 알림의 "바로 받기"로 들어온 받기 요청을 가져온다.
class TakeNewVideoDownloads
    implements UseCase<List<NewVideoDownloadRequest>, NoParams> {
  const TakeNewVideoDownloads(this._checker);

  final BackgroundChecker _checker;

  @override
  Future<List<NewVideoDownloadRequest>> call(NoParams params) =>
      _checker.takeDownloadRequests();
}

class WatchNewVideoDownloads
    implements StreamUseCase<NewVideoDownloadRequest, NoParams> {
  const WatchNewVideoDownloads(this._checker);

  final BackgroundChecker _checker;

  @override
  Stream<NewVideoDownloadRequest> call(NoParams params) =>
      _checker.watchDownloadRequests();
}

class MoveAppToBack implements UseCase<void, NoParams> {
  const MoveAppToBack(this._checker);

  final BackgroundChecker _checker;

  @override
  Future<void> call(NoParams params) => _checker.moveAppToBack();
}

/// 채널 상세(배너 · 구독자 수) 읽기.
class FetchChannelDetails implements UseCase<ChannelDetails, String> {
  const FetchChannelDetails(this._searcher);

  final ChannelSearcher _searcher;

  @override
  Future<ChannelDetails> call(String channelId) => _searcher.details(channelId);
}
