import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/saved_video.dart';
import 'package:music_download_play_app/features/search/domain/repositories/saved_video_repository.dart';
import 'package:music_download_play_app/features/covers/presentation/bloc/cover_cubit.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';
import 'package:music_download_play_app/features/search/domain/entities/video_stream.dart';

import '../../helpers/fakes.dart';

const _a = MediaHit(id: 'a', title: 'Song A', url: 'https://example.com/a');
const _b = MediaHit(id: 'b', title: 'Song B', url: 'https://example.com/b');

/// 끝나지 않는 움직임(재생 표시 등)이 있어 pumpAndSettle 대신 몇 프레임만 돌린다.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

SavedVideo _ready(MediaHit hit) => SavedVideo(
  hit: hit,
  ready: true,
  sources: [VideoStream(url: 'https://example.com/${hit.id}.m4a')],
);

NowPlayingCubit _player(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<NowPlayingCubit>();

void main() {
  testWidgets('임시 저장한 음원: 전체 재생을 누르면 메인 현재 재생 목록에 저장한 곡이 차례로 들어간다', (
    tester,
  ) async {
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(),
      previewPlayer: FakePreviewPlayer(),
    );
    await sl<SavedVideoRepository>().save([_ready(_a), _ready(_b)]);
    await tester.pumpWidget(const MusicApp(initialLocation: '/search/saved'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('saved-play-all')));
    await settle(tester);
    final state = _player(tester).state;
    expect(state.queue.map((t) => t.id), ['saved:a', 'saved:b']);
    expect(state.queue.first.source, TrackSource.saved);
    expect(state.queue.first.uri, 'https://example.com/a.m4a');
    expect(state.isPlaying, isTrue);
    // 재생 화면이 아니라 타일 상세 화면(하단 조작부)이 열린다.
    expect(find.byKey(const ValueKey('queue-bar-play')), findsOneWidget);
  });

  testWidgets(
    '저장한 곡 상세를 열면 재생 조작부가 있고(재생 전에는 아직 안 틀린다), 목록에서 곡을 틀면 그 곡부터 재생된다',
    (tester) async {
      await setUpTestDependencies(
        engine: FakeDownloaderEngine(info: const VideoInfo(_b)),
        previewPlayer: FakePreviewPlayer(),
      );
      await sl<SavedVideoRepository>().save([_ready(_a), _ready(_b)]);
      await tester.pumpWidget(const MusicApp(initialLocation: '/search/saved'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Song B'));
      await settle(tester);
      expect(find.byKey(const ValueKey('queue-bar-play')), findsOneWidget);
      expect(_player(tester).state.queue, isEmpty);
      await tester.pageBack();
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('saved-row-play-b')));
      await settle(tester);
      final state = _player(tester).state;
      expect(state.queue, hasLength(2));
      expect(state.track?.id, 'saved:b');
    },
  );

  testWidgets('아직 다 받지 못한 곡은 대기열에 넣지 않고 한 곡만 미리 듣기로 튼다', (tester) async {
    final player = FakePreviewPlayer();
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(info: const VideoInfo(_a)),
      previewPlayer: player,
    );
    await sl<SavedVideoRepository>().save(const [SavedVideo(hit: _a)]);
    await tester.pumpWidget(const MusicApp(initialLocation: '/search/saved'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('saved-row-play-a')));
    await settle(tester);
    expect(player.played, hasLength(1));
    expect(_player(tester).state.queue, isEmpty);
  });

  testWidgets('저장 주소가 없는 옛 저장분도 링크를 읽어 대기열에 넣는다', (tester) async {
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(),
      previewPlayer: FakePreviewPlayer(),
    );
    await sl<SavedVideoRepository>().save(const [
      SavedVideo(hit: _a, ready: true),
    ]);
    await tester.pumpWidget(const MusicApp(initialLocation: '/search/saved'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('saved-play-all')));
    await settle(tester);
    expect(_player(tester).state.queue.map((t) => t.id), ['saved:a']);
  });

  testWidgets('폰 크기에서도 상세 하단 조작부가 화면 안에 보인다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(info: const VideoInfo(_b)),
      previewPlayer: FakePreviewPlayer(),
    );
    await sl<SavedVideoRepository>().save([_ready(_a), _ready(_b)]);
    await tester.pumpWidget(const MusicApp(initialLocation: '/search/saved'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Song B'));
    await settle(tester);
    final rect = tester.getRect(find.byKey(const ValueKey('queue-bar-play')));
    expect(rect.height, greaterThan(20));
    expect(rect.bottom, lessThanOrEqualTo(2340 / 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('임시 저장한 곡의 썸네일이 곡 커버로 알려져 미니 플레이어 · 알림이 쓴다', (tester) async {
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(),
      previewPlayer: FakePreviewPlayer(),
    );
    await sl<SavedVideoRepository>().save([
      _ready(
        const MediaHit(
          id: 'c',
          title: 'Song C',
          url: 'https://example.com/c',
          thumbnailUrl: 'https://img.test/c.jpg',
        ),
      ),
    ]);
    await tester.pumpWidget(const MusicApp(initialLocation: '/search/saved'));
    await tester.pumpAndSettle();

    final covers = tester
        .element(find.byType(Scaffold).first)
        .read<CoverCubit>()
        .state;
    expect(covers[CoverKey.track('saved:c')]?.url, 'https://img.test/c.jpg');
  });
}
