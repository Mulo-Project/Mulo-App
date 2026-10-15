import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/repositories/download_queue_repository.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/background_status.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/channel_details.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/channel_hit.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/new_video_download_request.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/subscribed_channel.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_source.dart';
import 'package:music_download_play_app/features/subscriptions/domain/repositories/background_checker.dart';
import 'package:music_download_play_app/features/subscriptions/domain/repositories/channel_searcher.dart';
import 'package:music_download_play_app/features/subscriptions/domain/usecases/subscription_usecases.dart';
import 'package:music_download_play_app/features/subscriptions/presentation/bloc/channel_search_cubit.dart';
import 'package:music_download_play_app/features/subscriptions/presentation/bloc/new_videos_cubit.dart';
import 'package:music_download_play_app/features/subscriptions/presentation/bloc/subscriptions_cubit.dart';

import '../../helpers/fakes.dart';

class _FakeSearcher implements ChannelSearcher {
  _FakeSearcher({this.fail = false});

  final bool fail;
  final queries = <String>[];

  @override
  Future<ChannelDetails> details(String channelId) async =>
      const ChannelDetails(bannerUrl: 'https://example.com/banner.jpg');

  @override
  Future<List<ChannelHit>> search(String query) async {
    queries.add(query);
    if (fail) throw StateError('search failed');
    return const [
      ChannelHit(id: 'UCaaaaaaaaaaaaaaaaaaaaaa', name: 'Channel A'),
    ];
  }
}

void main() {
  setUp(() => setUpTestDependencies());

  group('채널 검색', () {
    test('검색어를 다듬어 찾고 결과를 보여 준다', () async {
      final searcher = _FakeSearcher();
      final cubit = ChannelSearchCubit(SearchChannels(searcher));
      await cubit.search('  lofi  ');
      expect(searcher.queries, ['lofi']);
      expect(cubit.state.status, ChannelSearchStatus.done);
      expect(cubit.state.results.single.name, 'Channel A');
      await cubit.search('   ');
      expect(cubit.state.status, ChannelSearchStatus.idle);
    });

    test('찾기에 실패하면 실패 상태가 된다', () async {
      final cubit = ChannelSearchCubit(
        SearchChannels(_FakeSearcher(fail: true)),
      );
      await cubit.search('x');
      expect(cubit.state.status, ChannelSearchStatus.failed);
    });

    test('검색 결과로 구독하면 채널 페이지를 읽지 않고 채널 id로 구독한다', () async {
      final subs = sl<SubscriptionsCubit>();
      const hit = ChannelHit(id: 'UCaaaaaaaaaaaaaaaaaaaaaa', name: 'Channel A');
      expect(
        await subs.subscribe(SubscribeParams.fromHit(hit)),
        SubscribeResult.added,
      );
      expect(subs.state.isSubscribedId(hit.id), isTrue);
      expect(
        await subs.subscribe(SubscribeParams.fromHit(hit)),
        SubscribeResult.already,
      );
      await subs.unsubscribe(hit.id);
      expect(subs.state.isSubscribedId(hit.id), isFalse);
    });
  });

  group('분류 조건', () {
    test('조건이 없으면 모두, 있으면 맞는 분류와 분류를 모르는 영상만 받아들인다', () {
      final all = SubscribedChannel(
        id: 'a',
        name: 'a',
        baselineAt: DateTime(2026),
      );
      final music = all.copyWith(categories: {'Music'});
      expect(all.accepts(['Gaming']), isTrue);
      expect(music.accepts(['Music', 'Entertainment']), isTrue);
      expect(music.accepts(['Gaming']), isFalse);
      expect(music.accepts(const []), isTrue);
    });

    test('구독할 때 고른 분류가 저장되고 나중에 바꿀 수 있다', () async {
      final subs = sl<SubscriptionsCubit>();
      const hit = ChannelHit(id: 'UCaaaaaaaaaaaaaaaaaaaaaa', name: 'Channel A');
      await subs.subscribe(
        SubscribeParams.fromHit(hit, categories: {'Music', 'Gaming'}),
      );
      expect(subs.state.channels.single.categories, {'Music', 'Gaming'});
      await subs.setCategories(hit.id, {});
      expect(subs.state.channels.single.filtersCategories, isFalse);
    });
  });

  group('채널별 저장 위치와 알림의 바로 받기', () {
    const hit = ChannelHit(id: 'UCaaaaaaaaaaaaaaaaaaaaaa', name: 'Channel A');
    const request = NewVideoDownloadRequest(
      videoId: 'v1',
      title: 'Song',
      channelId: 'UCaaaaaaaaaaaaaaaaaaaaaa',
      channelName: 'Channel A',
    );

    test('구독할 때 정한 저장 위치가 저장되고 바꾸거나 되돌릴 수 있다', () async {
      final subs = sl<SubscriptionsCubit>();
      await subs.subscribe(SubscribeParams.fromHit(hit, savePath: '/music/a'));
      expect(subs.state.channels.single.savePath, '/music/a');
      await subs.setSavePath(hit.id, '');
      expect(subs.state.channels.single.savePath, isEmpty);
    });

    test('바로 받기는 그 채널의 저장 위치로 받기 대기열에 넣는다', () async {
      final subs = sl<SubscriptionsCubit>();
      await subs.subscribe(SubscribeParams.fromHit(hit, savePath: '/music/a'));
      final queued = await sl<NewVideosCubit>().handleDownloadRequest(request);
      expect(queued, isTrue);
      final queue = sl<DownloadQueueRepository>() as MemoryDownloadQueue;
      expect(queue.requests.single.savePath, '/music/a');
      expect(queue.requests.single.url, 'https://www.youtube.com/watch?v=v1');
      expect((sl<BackgroundChecker>() as FakeBackgroundChecker).movedToBack, 0);
    });

    test('앱이 뒤에 있다가 켜진 요청은 받기를 시작한 뒤 앱을 다시 뒤로 보낸다', () async {
      await sl<SubscriptionsCubit>().subscribe(SubscribeParams.fromHit(hit));
      await sl<NewVideosCubit>().handleDownloadRequest(
        const NewVideoDownloadRequest(
          videoId: 'v1',
          title: 'Song',
          channelId: 'UCaaaaaaaaaaaaaaaaaaaaaa',
          background: true,
        ),
      );
      expect((sl<BackgroundChecker>() as FakeBackgroundChecker).movedToBack, 1);
    });

    test('이미 받았거나 샘플인 영상은 다시 받지 않는다', () async {
      final queue = sl<DownloadQueueRepository>() as MemoryDownloadQueue;
      queue.existing['https://www.youtube.com/watch?v=v1'] =
          const ExistingDownload(inQueue: true);
      final cubit = sl<NewVideosCubit>();
      expect(await cubit.handleDownloadRequest(request), isFalse);
      expect(
        await cubit.handleDownloadRequest(
          const NewVideoDownloadRequest(
            videoId: 'sample-1',
            title: 's',
            channelId: 'sample-a',
          ),
        ),
        isFalse,
      );
      expect(queue.requests, isEmpty);
    });
  });

  group('백그라운드 확인 진단', () {
    test('지금 확인은 한 번 돌리고 마지막 확인 결과를 읽어 온다', () async {
      final fake = sl<BackgroundChecker>() as FakeBackgroundChecker;
      fake.statusAfterCheck = BackgroundStatus(
        scheduled: true,
        lastRunAt: DateTime(2026, 1, 1),
        channels: 2,
        failedChannels: 1,
      );
      final cubit = sl<SubscriptionsCubit>();
      await cubit.checkNow();
      expect(fake.checkedNow, 1);
      expect(cubit.state.checking, isFalse);
      expect(cubit.state.status?.failedChannels, 1);
    });
  });

  group('임시 확인 기능', () {
    test('알림 확인 버튼은 샘플 알림을 한 번 띄운다', () async {
      await sl<SubscriptionsCubit>().showTestNotification();
      expect((sl<BackgroundChecker>() as FakeBackgroundChecker).testShown, 1);
    });

    test('샘플 새 영상은 목록에 보이지만 받기 대기열에는 들어가지 않는다', () async {
      final cubit = sl<NewVideosCubit>();
      cubit.showSample();
      expect(cubit.state.count, 5);
      cubit.toggleAll();
      expect(await cubit.startSelected(), 0);
      final queue = await sl<DownloadQueueRepository>().watchQueue().first;
      expect(queue, isEmpty);
      await cubit.markSeen();
      expect(cubit.state.count, 0);
    });
  });
}
