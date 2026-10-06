import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';
import 'package:music_download_play_app/features/search/data/engine/cached_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/local_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/server_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/preview_cubit.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

const _a = MediaHit(id: 'a', title: 'Song A', url: 'https://example.com/a');
const _b = MediaHit(id: 'b', title: 'Song B', url: 'https://example.com/b');

PreviewCubit _cubit(FakeDownloaderEngine e, FakePreviewPlayer p) =>
    PreviewCubit(
      ResolveAudioStream(e),
      PlayPreview(p),
      StopPreview(p),
      WatchPreviewCompleted(p),
    );

void main() {
  group('엔진: 오디오 스트림 주소', () {
    test('LocalEngine: 오디오 형식 하나를 골라 주소와 헤더를 읽는다', () async {
      List<String>? args;
      final engine = LocalEngine(
        run: (_, a) async {
          args = a;
          return (
            exitCode: 0,
            stdout: jsonEncode({
              'id': 'v',
              'url': 'https://rr.googlevideo.com/audio',
              'http_headers': {'User-Agent': 'ua', 'Ignored': 1},
            }),
            stderr: '',
          );
        },
      );
      final stream = await engine.resolveAudioStream('https://x/v');
      expect(stream.url, 'https://rr.googlevideo.com/audio');
      expect(stream.headers, {'User-Agent': 'ua'});
      expect(args, contains('--no-playlist'));
      expect(args![args!.indexOf('-f') + 1], contains('bestaudio'));
      expect(args!.last, 'https://x/v');
    });

    test('LocalEngine: 주소가 없으면 실패다', () async {
      final engine = LocalEngine(
        run: (_, _) async =>
            (exitCode: 0, stdout: jsonEncode({'id': 'v'}), stderr: ''),
      );
      await expectLater(
        engine.resolveAudioStream('https://x/v'),
        throwsA(
          isA<EngineException>().having(
            (e) => e.failure,
            'failure',
            EngineFailure.failed,
          ),
        ),
      );
    });

    test('ServerEngine: 스트림 주소 조회는 없어서 쓸 수 없다', () async {
      final engine = ServerEngine(
        baseUrl: 'https://s',
        get: (_, _) async => (status: 200, body: '{}'),
      );
      await expectLater(
        engine.resolveAudioStream('https://x/v'),
        throwsA(
          isA<EngineException>().having(
            (e) => e.failure,
            'failure',
            EngineFailure.unavailable,
          ),
        ),
      );
    });

    test('CachedDownloaderEngine: 같은 곡의 스트림 주소는 다시 읽지 않는다', () async {
      final inner = FakeDownloaderEngine();
      final engine = CachedDownloaderEngine(inner);
      await engine.resolveAudioStream('https://x/v');
      await engine.resolveAudioStream('https://x/v');
      expect(inner.streams, ['https://x/v']);
    });
  });

  group('PreviewCubit', () {
    test('누르면 스트림 주소를 받아 재생하고, 다시 누르면 멈춘다', () async {
      final engine = FakeDownloaderEngine();
      final player = FakePreviewPlayer();
      final cubit = _cubit(engine, player);

      expect(await cubit.toggle(_a), isNull);
      expect(engine.streams, [_a.url]);
      expect(player.played, ['https://stream.test/${_a.url}']);
      expect(cubit.state.isActive('a'), isTrue);
      expect(cubit.state.status, PreviewStatus.playing);

      await cubit.toggle(_a);
      expect(cubit.state.status, PreviewStatus.idle);
      expect(player.playing, isFalse);
    });

    test('다른 곡을 미리 들으면 앞의 곡은 멈춘다 (한 번에 한 곡)', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(), player);

      await cubit.toggle(_a);
      await cubit.toggle(_b);
      expect(player.stops, 1);
      expect(player.played.length, 2);
      expect(cubit.state.hitId, 'b');
      expect(cubit.state.isActive('a'), isFalse);
    });

    test('준비 중에 멈추면 늦게 도착한 소리는 나지 않는다', () async {
      final gate = Completer<void>();
      final player = FakePreviewPlayer();
      final cubit = _cubit(
        FakeDownloaderEngine(streamGate: gate.future),
        player,
      );

      final started = cubit.toggle(_a);
      await pumpEventQueue();
      expect(cubit.state.status, PreviewStatus.loading);

      await cubit.stop();
      gate.complete();
      expect(await started, isNull);
      expect(player.played, isEmpty);
      expect(cubit.state.status, PreviewStatus.idle);
    });

    test('시작하지 못하면 까닭을 돌려주고 멈춘 상태로 돌아온다', () async {
      final cubit = _cubit(
        FakeDownloaderEngine(streamFailure: EngineFailure.unavailable),
        FakePreviewPlayer(),
      );
      expect(await cubit.toggle(_a), EngineFailure.unavailable);
      expect(cubit.state.status, PreviewStatus.idle);

      final playerFails = _cubit(
        FakeDownloaderEngine(),
        FakePreviewPlayer(failure: EngineFailure.failed),
      );
      expect(await playerFails.toggle(_a), EngineFailure.failed);
      expect(playerFails.state.status, PreviewStatus.idle);
    });

    test('끝까지 재생되면 멈춘 상태가 된다', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(), player);
      await cubit.toggle(_a);

      player.complete();
      await pumpEventQueue();
      expect(cubit.state.status, PreviewStatus.idle);
    });
  });

  group('화면', () {
    const hit = MediaHit(
      id: 'v',
      title: 'Song',
      url: 'https://www.youtube.com/watch?v=v',
      uploader: 'Chan',
    );

    Future<FakePreviewPlayer> openSearch(
      WidgetTester tester, {
      FakeDownloaderEngine? engine,
    }) async {
      final player = FakePreviewPlayer();
      await setUpTestDependencies(
        engine:
            engine ??
            FakeDownloaderEngine(
              pages: const [
                SearchPage(items: [hit], hasNext: false),
              ],
              info: const VideoInfo(hit),
            ),
        previewPlayer: player,
      );
      await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      return player;
    }

    Future<void> previewFromMenu(WidgetTester tester) async {
      await tester.longPress(find.text('Song'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
    }

    testWidgets('길게 누르기 메뉴에서 미리 듣고, 메뉴나 멈춤 버튼으로 멈춘다', (tester) async {
      final player = await openSearch(tester);
      expect(find.byKey(const ValueKey('preview-indicator')), findsNothing);

      await previewFromMenu(tester);
      expect(player.playing, isTrue);
      expect(find.byKey(const ValueKey('preview-indicator')), findsOneWidget);

      await tester.longPress(find.text('Song'));
      await tester.pumpAndSettle();
      expect(find.text('Stop preview'), findsOneWidget);
      await tester.tap(find.text('Stop preview'));
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
      expect(find.byKey(const ValueKey('preview-indicator')), findsNothing);

      await previewFromMenu(tester);
      await tester.tap(find.byKey(const ValueKey('preview-indicator')));
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
    });

    testWidgets('쓸 수 없는 기기에서는 안내만 띄운다', (tester) async {
      final player = await openSearch(
        tester,
        engine: FakeDownloaderEngine(
          pages: const [
            SearchPage(items: [hit], hasNext: false),
          ],
          streamFailure: EngineFailure.unavailable,
        ),
      );
      await previewFromMenu(tester);
      expect(find.text("Preview isn't available on this device."), findsOne);
      expect(player.played, isEmpty);
    });

    testWidgets('상세 화면 버튼으로 미리 듣고, 화면을 나가면 멈춘다', (tester) async {
      final player = await openSearch(tester);
      await tester.tap(find.text('Song'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);
      expect(find.text('Stop preview'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
      expect(find.byKey(const ValueKey('preview-indicator')), findsNothing);
    });

    testWidgets('다른 탭으로 가면 멈춘다', (tester) async {
      final player = await openSearch(tester);
      await previewFromMenu(tester);
      expect(player.playing, isTrue);

      await tester.tap(find.byKey(const ValueKey('nav-Home')));
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
    });

    testWidgets('메인 재생과 섞이지 않는다: 미리 들으면 메인은 멈추고, 메인을 틀면 미리 듣기가 멈춘다', (
      tester,
    ) async {
      final player = await openSearch(tester);
      final now =
          tester.element(find.byType(AppBottomNav)).read<NowPlayingCubit>()
            ..playQueue(TestData.tracks);
      await tester.pump();
      expect(now.state.isPlaying, isTrue);

      await previewFromMenu(tester);
      expect(player.playing, isTrue);
      expect(now.state.isPlaying, isFalse);
      expect(now.state.queue, TestData.tracks); // 대기열은 그대로

      now.togglePlay();
      await tester.pumpAndSettle();
      expect(now.state.isPlaying, isTrue);
      expect(player.playing, isFalse);
    });
  });
}
