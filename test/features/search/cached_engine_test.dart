import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/data/engine/cached_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/media_detail_cubit.dart';

import '../../helpers/fakes.dart';

const _hit = MediaHit(
  id: 'v',
  title: 'Song',
  url: 'https://www.youtube.com/watch?v=v',
  channelUrl: 'https://www.youtube.com/@c',
);

/// 곡 · 채널 응답을 테스트가 직접 내보내는 엔진.
class _GatedEngine extends FakeDownloaderEngine {
  final info$ = Completer<MediaInfo>();
  final channel$ = Completer<ChannelInfo>();
  final order = <String>[];

  @override
  Future<MediaInfo> fetchInfo(String url) {
    order.add('info');
    return info$.future;
  }

  @override
  Future<ChannelInfo> fetchChannel(String url) {
    order.add('channel');
    return channel$.future;
  }
}

void main() {
  group('CachedDownloaderEngine', () {
    test('같은 주소는 한 번만 읽고 읽는 중인 요청도 함께 쓴다', () async {
      final inner = FakeDownloaderEngine(info: const VideoInfo(_hit));
      final engine = CachedDownloaderEngine(inner);
      await Future.wait([engine.fetchInfo('u'), engine.fetchInfo('u')]);
      await engine.fetchInfo('u');
      expect(inner.infos, ['u']);
      await engine.fetchInfo('other');
      expect(inner.infos, ['u', 'other']);
    });

    test('채널 정보도 기억한다', () async {
      final inner = FakeDownloaderEngine(
        channel: const ChannelInfo(subscriberCount: 3),
      );
      final engine = CachedDownloaderEngine(inner);
      await engine.fetchChannel('c');
      await engine.fetchChannel('c');
      expect(inner.channels, ['c']);
    });

    test('실패는 기억하지 않아 다시 시도한다', () async {
      final inner = FakeDownloaderEngine(
        error: const EngineException(EngineFailure.network),
      );
      final engine = CachedDownloaderEngine(inner);
      await expectLater(engine.fetchInfo('u'), throwsA(isA<EngineException>()));
      await expectLater(engine.fetchInfo('u'), throwsA(isA<EngineException>()));
      expect(inner.infos, ['u', 'u']);
    });

    test('기억한 시간이 지나면 다시 읽는다', () async {
      var now = DateTime(2026);
      final inner = FakeDownloaderEngine(info: const VideoInfo(_hit));
      final engine = CachedDownloaderEngine(
        inner,
        ttl: const Duration(minutes: 1),
        now: () => now,
      );
      await engine.fetchInfo('u');
      now = now.add(const Duration(seconds: 59));
      await engine.fetchInfo('u');
      expect(inner.infos, ['u']);
      now = now.add(const Duration(seconds: 2));
      await engine.fetchInfo('u');
      expect(inner.infos, ['u', 'u']);
    });

    test('오래된 것부터 버리고, 검색은 기억하지 않는다', () async {
      final inner = FakeDownloaderEngine(
        info: const VideoInfo(_hit),
        pages: const [SearchPage(items: [], hasNext: false)],
      );
      final engine = CachedDownloaderEngine(inner, maxEntries: 2);
      await engine.fetchInfo('a');
      await engine.fetchInfo('b');
      await engine.fetchInfo('c'); // a가 밀려난다
      await engine.fetchInfo('a');
      expect(inner.infos, ['a', 'b', 'c', 'a']);

      await engine.search('q');
      await engine.search('q');
      expect(inner.searches.length, 2);
    });
  });

  group('MediaDetailCubit 로딩', () {
    test('채널 주소를 이미 알면 곡 정보를 기다리지 않고 채널을 읽는다', () async {
      final engine = _GatedEngine();
      final cubit = MediaDetailCubit(
        _hit,
        FetchMediaInfo(engine),
        FetchChannelInfo(engine),
        OpenLink(FakeLinkOpener()),
      );
      final done = cubit.load();
      await Future<void>.delayed(Duration.zero);
      expect(engine.order, unorderedEquals(['info', 'channel'])); // 둘 다 바로 시작

      // 채널이 먼저 와도 먼저 보인다.
      engine.channel$.complete(
        const ChannelInfo(thumbnailUrl: 'https://img/a', subscriberCount: 7),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.hit.subscriberCount, 7);
      expect(cubit.state.loading, isTrue);

      engine.info$.complete(
        const VideoInfo(
          MediaHit(id: 'v', title: 'Song', url: 'u', viewCount: 9),
        ),
      );
      await done;
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.hit.viewCount, 9);
      expect(cubit.state.hit.subscriberCount, 7); // 채널 정보는 그대로
    });
  });
}
