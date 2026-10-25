import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/repositories/download_queue_repository.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/channel_hit.dart';
import 'package:music_download_play_app/features/subscriptions/data/datasources/youtube_feed_client.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/feed_video.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/subscribed_channel.dart';
import 'package:music_download_play_app/features/subscriptions/domain/repositories/background_checker.dart';
import 'package:music_download_play_app/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:music_download_play_app/features/subscriptions/domain/usecases/subscription_usecases.dart';
import 'package:music_download_play_app/features/subscriptions/presentation/bloc/new_videos_cubit.dart';
import 'package:music_download_play_app/features/subscriptions/presentation/bloc/subscriptions_cubit.dart';

import '../../helpers/fakes.dart';

const _feedXml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015" xmlns:media="http://search.yahoo.com/mrss/" xmlns="http://www.w3.org/2005/Atom">
 <title>Some Channel</title>
 <entry>
  <id>yt:video:AAA11111111</id>
  <yt:videoId>AAA11111111</yt:videoId>
  <yt:channelId>UCaaaaaaaaaaaaaaaaaaaaaa</yt:channelId>
  <title>Song &amp; Dance &#39;26</title>
  <published>2026-10-11T10:00:00+00:00</published>
  <author><name>Some Channel</name></author>
  <media:group>
   <media:thumbnail url="https://i.ytimg.com/vi/AAA11111111/hqdefault.jpg" width="480" height="360"/>
   <media:community><media:statistics views="1234"/></media:community>
  </media:group>
 </entry>
 <entry>
  <yt:videoId>BBB22222222</yt:videoId>
  <title>Older</title>
  <published>2026-10-01T10:00:00+00:00</published>
 </entry>
 <entry><title>Broken, no id</title></entry>
</feed>''';

const _channelId = 'UCaaaaaaaaaaaaaaaaaaaaaa';
final _t0 = DateTime.utc(2026, 10, 5);

SubscribedChannel _channel({
  bool enabled = true,
  Set<String> categories = const {},
  DateTime? baseline,
}) => SubscribedChannel(
  id: _channelId,
  name: 'Some Channel',
  url: 'https://www.youtube.com/channel/$_channelId',
  baselineAt: baseline ?? _t0,
  enabled: enabled,
  categories: categories,
);

FeedVideo _video(String id, DateTime at) =>
    FeedVideo(id: id, title: 't-$id', publishedAt: at, author: 'Some Channel');

/// 분류를 정해 둔 영상 정보를 돌려주는 엔진.
class _CategoryEngine extends FakeDownloaderEngine {
  _CategoryEngine(this.categories);

  final Map<String, List<String>> categories;

  @override
  Future<MediaInfo> fetchInfo(String url) async {
    final id = Uri.parse(url).queryParameters['v']!;
    return VideoInfo(
      MediaHit(
        id: id,
        title: id,
        url: url,
        categories: categories[id] ?? const [],
      ),
    );
  }
}

void main() {
  group('채널 피드 읽기', () {
    test('RSS에서 영상 id · 제목 · 올린 시각 · 이미지 · 조회수를 읽는다', () {
      final videos = parseFeed(_feedXml);
      expect(videos.map((v) => v.id), ['AAA11111111', 'BBB22222222']);
      final first = videos.first;
      expect(first.title, "Song & Dance '26");
      expect(first.publishedAt, DateTime.utc(2026, 10, 11, 10));
      expect(first.author, 'Some Channel');
      expect(first.thumbnailUrl, contains('AAA11111111'));
      expect(first.viewCount, 1234);
      expect(first.url, 'https://www.youtube.com/watch?v=AAA11111111');
    });

    test('채널 주소 · 페이지에서 채널 id를 알아낸다', () async {
      final client = YoutubeFeedClient(
        get: (uri) async => (status: 200, body: '{"externalId":"$_channelId"}'),
      );
      expect(
        await client.resolveChannelId(
          'https://www.youtube.com/channel/$_channelId',
        ),
        _channelId,
      );
      expect(
        await client.resolveChannelId('https://www.youtube.com/@handle'),
        _channelId,
      );
      expect(await client.resolveChannelId('https://soundcloud.com/x'), isNull);
    });
  });

  group('새 영상 확인', () {
    test('기준 시각 이후 영상만 최신 순으로 돌려주고 꺼진 채널은 읽지 않는다', () async {
      final feed = FakeChannelFeed(
        feeds: {
          _channelId: [
            _video('old', DateTime.utc(2026, 10, 1)),
            _video('new1', DateTime.utc(2026, 10, 6)),
            _video('new2', DateTime.utc(2026, 10, 7)),
          ],
        },
      );
      final result = await CheckNewVideos(feed)([
        _channel(),
        _channel(enabled: false),
      ]);
      expect(result, hasLength(1));
      expect(result.single.videos.map((v) => v.id), ['new2', 'new1']);
      expect(result.single.latestPublishedAt, DateTime.utc(2026, 10, 7));
    });

    test('읽지 못한 채널은 건너뛴다', () async {
      final result = await CheckNewVideos(
        FakeChannelFeed(failing: {_channelId}),
      )([_channel()]);
      expect(result, isEmpty);
    });

    test('첫 구독은 기준 시각을 지금으로 잡아 기존 영상이 새 영상이 아니다', () async {
      final now = DateTime.utc(2026, 10, 10);
      final channel =
          await CreateSubscription(FakeChannelFeed(), now: () => now)(
            SubscribeParams(
              channelUrl: 'https://www.youtube.com/channel/$_channelId',
              name: 'Some Channel',
            ),
          );
      expect(channel?.baselineAt, now);
      final result = await CheckNewVideos(
        FakeChannelFeed(
          feeds: {
            _channelId: [_video('existing', DateTime.utc(2026, 10, 9))],
          },
        ),
      )([channel!]);
      expect(result.single.videos, isEmpty);
    });

    test('markSeenChannels는 기준 시각을 앞으로만 당긴다', () {
      final later = DateTime.utc(2026, 10, 8);
      expect(
        markSeenChannels([_channel()], {_channelId: later}).single.baselineAt,
        later,
      );
      expect(
        markSeenChannels(
          [_channel(baseline: later)],
          {_channelId: _t0},
        ).single.baselineAt,
        later,
      );
    });
  });

  group('구독 상태', () {
    setUp(() => setUpTestDependencies());

    test('구독하면 저장되고 같은 채널은 다시 구독되지 않는다', () async {
      final cubit = sl<SubscriptionsCubit>();
      const params = SubscribeParams(
        channelUrl: 'https://www.youtube.com/channel/$_channelId',
        name: 'Some Channel',
      );
      expect(await cubit.subscribe(params), SubscribeResult.added);
      expect(await cubit.subscribe(params), SubscribeResult.already);
      expect(cubit.state.channels, hasLength(1));
      expect(cubit.state.isSubscribed(params.channelUrl), isTrue);
      expect(
        (sl<SubscriptionRepository>() as MemorySubscriptionRepository).channels,
        hasLength(1),
      );
      expect(
        (sl<BackgroundChecker>() as FakeBackgroundChecker).lastChannels,
        hasLength(1),
      );
      await cubit.unsubscribeByUrl(params.channelUrl);
      expect(cubit.state.channels, isEmpty);
    });

    test('고른 채널들을 한 번에 구독하되 이미 구독한 채널은 더하지 않는다', () async {
      final cubit = sl<SubscriptionsCubit>();
      const one = ChannelHit(id: 'UCone', name: '하나');
      const two = ChannelHit(id: 'UCtwo', name: '둘');
      await cubit.subscribe(SubscribeParams.fromHit(one));
      final added = await cubit.subscribeAll([
        SubscribeParams.fromHit(one),
        SubscribeParams.fromHit(two),
        SubscribeParams.fromHit(two),
      ]);
      expect(added, 1);
      expect(cubit.state.channels.map((c) => c.id), ['UCone', 'UCtwo']);
      expect(
        (sl<BackgroundChecker>() as FakeBackgroundChecker).lastChannels,
        hasLength(2),
      );
    });

    test('채널 id를 알 수 없는 주소는 구독에 실패한다', () async {
      final result = await sl<SubscriptionsCubit>().subscribe(
        const SubscribeParams(
          channelUrl: 'https://www.youtube.com/@handle',
          name: 'x',
        ),
      );
      expect(result, SubscribeResult.failed);
    });
  });

  group('새 영상 목록', () {
    Future<NewVideosCubit> boot({
      required List<SubscribedChannel> channels,
      required Map<String, List<FeedVideo>> feeds,
      Map<String, List<String>> categories = const {},
    }) async {
      await setUpTestDependencies(
        subscriptions: MemorySubscriptionRepository(channels: channels),
        channelFeed: FakeChannelFeed(feeds: feeds),
        engine: _CategoryEngine(categories),
      );
      return sl<NewVideosCubit>();
    }

    final fresh = [
      _video('v1', DateTime.utc(2026, 10, 6)),
      _video('v2', DateTime.utc(2026, 10, 7)),
    ];

    test('확인하면 새 영상이 채널별로 묶여 나오고 고른 것만 받기 대기열에 들어간다', () async {
      final cubit = await boot(
        channels: [_channel()],
        feeds: {_channelId: fresh},
      );
      await cubit.check();
      expect(cubit.state.groups.single.videos.map((v) => v.id), ['v2', 'v1']);
      expect(cubit.state.count, 2);

      cubit.toggle('v1');
      expect(await cubit.startSelected(), 1);
      final queue = await sl<DownloadQueueRepository>().watchQueue().first;
      expect(queue.single.title, 't-v1');
      expect(cubit.state.selected, isEmpty);
    });

    test('모두 선택은 보이는 영상 전체를 고르고, 한 번 더 누르면 해제한다', () async {
      final cubit = await boot(
        channels: [_channel()],
        feeds: {_channelId: fresh},
      );
      await cubit.check();
      cubit.toggleAll();
      expect(cubit.state.selected, {'v1', 'v2'});
      cubit.toggleAll();
      expect(cubit.state.selected, isEmpty);
    });

    test('분류 조건: 맞지 않는 분류는 숨기고 분류를 모르는 영상은 보여 준다', () async {
      final cubit = await boot(
        channels: [
          _channel(categories: {'Music'}),
        ],
        feeds: {
          _channelId: [
            _video('music', DateTime.utc(2026, 10, 6)),
            _video('vlog', DateTime.utc(2026, 10, 7)),
            _video('unknown', DateTime.utc(2026, 10, 8)),
          ],
        },
        categories: {
          'music': ['Music'],
          'vlog': ['People & Blogs'],
        },
      );
      await cubit.check();
      // 분류 확인이 끝날 때까지 기다린다.
      await cubit.stream.firstWhere((s) => !s.resolving);
      expect(cubit.state.groups.single.videos.map((v) => v.id), [
        'unknown',
        'music',
      ]);
    });

    test('한 번 본 영상은 목록에는 남아도 앱을 켤 때 다시 안내하지 않는다', () async {
      final cubit = await boot(
        channels: [_channel()],
        feeds: {_channelId: fresh},
      );
      await cubit.check();
      expect(cubit.state.count, greaterThan(0));
      expect(cubit.state.unseenCount, cubit.state.count);

      await cubit.acknowledge();
      expect(cubit.state.unseenCount, 0);
      expect(cubit.state.count, greaterThan(0)); // 목록은 그대로

      // 다시 확인해도(다음 실행) 같은 영상은 안내 대상이 아니다.
      await cubit.check();
      expect(cubit.state.count, greaterThan(0));
      expect(cubit.state.unseenCount, 0);
    });

    test('화면을 닫으면 확인한 채널의 기준 시각이 당겨져 다시 뜨지 않는다', () async {
      final cubit = await boot(
        channels: [_channel()],
        feeds: {_channelId: fresh},
      );
      await cubit.check();
      await cubit.markSeen();
      expect(cubit.state.count, 0);
      final saved = sl<SubscriptionsCubit>().state.channels.single;
      expect(saved.baselineAt, DateTime.utc(2026, 10, 7));
      await cubit.check();
      expect(cubit.state.count, 0);
    });
  });
}
