import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/repositories/download_queue_repository.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/channel_hit.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/subscribed_channel.dart';
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
