import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/media_session.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';
import 'package:music_download_play_app/features/search/presentation/widgets/preview_control.dart';
import 'package:music_download_play_app/features/search/data/engine/cached_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/explode_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/local_engine.dart';
import 'package:music_download_play_app/features/search/data/engine/server_engine.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_language.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_stream.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/preview_snapshot.dart';
import 'package:music_download_play_app/features/search/domain/entities/video_stream.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/preview_cubit.dart';
import 'package:music_download_play_app/features/search/presentation/screens/media_detail_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

const _a = MediaHit(id: 'a', title: 'Song A', url: 'https://example.com/a');
const _b = MediaHit(id: 'b', title: 'Song B', url: 'https://example.com/b');

PreviewCubit _cubit(FakeDownloaderEngine e, FakePreviewPlayer p) =>
    PreviewCubit(
      ResolveAudioStream(e),
      PlayPreview(p),
      RememberPreview(p),
      CurrentPreview(p),
      SeekPreview(p),
      PausePreview(p),
      ResumePreview(p),
      StopPreview(p),
      WatchPreviewCompleted(p),
      WatchPreviewProgress(p),
      WatchPreviewFailures(p),
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

    test('LocalEngine: 기본으로 실패하면 다른 클라이언트로 한 번 더 읽는다', () async {
      final calls = <List<String>>[];
      final engine = LocalEngine(
        run: (_, a) async {
          calls.add(a);
          if (calls.length == 1) {
            return (exitCode: 1, stdout: '', stderr: 'format not available');
          }
          return (
            exitCode: 0,
            stdout: jsonEncode({'url': 'https://rr.googlevideo.com/audio'}),
            stderr: '',
          );
        },
      );
      final stream = await engine.resolveAudioStream('https://x/v');
      expect(stream.url, 'https://rr.googlevideo.com/audio');
      expect(calls, hasLength(2));
      expect(calls.last, contains('youtube:player_client=android_vr'));
    });

    test(
      'YoutubeExplodeEngine: 유튜브 곡은 라이브러리가 읽은 주소를 쓰고, 못 읽으면 안쪽 엔진으로 넘긴다',
      () async {
        final inner = FakeDownloaderEngine();
        var fail = false;
        final engine = YoutubeExplodeEngine(
          inner,
          reader: (id, {language}) async {
            if (fail) throw const EngineException(EngineFailure.failed);
            return AudioStream(url: 'https://explode/$id');
          },
        );
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        expect(
          (await engine.resolveAudioStream(url)).url,
          'https://explode/dQw4w9WgXcQ',
        );
        fail = true;
        expect(
          (await engine.resolveAudioStream(url)).url,
          'https://stream.test/$url',
        );
        // 유튜브 주소가 아니면 처음부터 안쪽 엔진.
        fail = false;
        expect(
          (await engine.resolveAudioStream('https://soundcloud.com/a/b')).url,
          'https://stream.test/https://soundcloud.com/a/b',
        );
      },
    );

    test(
      'YoutubeExplodeEngine: 소리가 든 영상 주소는 라이브러리가 먼저 읽고, 못 읽으면 안쪽 엔진으로 넘긴다',
      () async {
        final inner = FakeDownloaderEngine();
        VideoStream? found = const VideoStream(
          url: 'https://explode/video',
          muxed: true,
        );
        final engine = YoutubeExplodeEngine(
          inner,
          videoReader: (id, maxHeight) async => found,
        );
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        expect(
          (await engine.resolveVideoStream(url)).url,
          'https://explode/video',
        );
        found = null;
        expect(
          (await engine.resolveVideoStream(url)).url,
          isNot('https://explode/video'),
        );
      },
    );

    test('YoutubeExplodeEngine: 고른 오디오 언어를 읽는 쪽에 넘긴다', () async {
      final inner = FakeDownloaderEngine();
      final languages = <String?>[];
      final engine = YoutubeExplodeEngine(
        inner,
        reader: (id, {language}) async {
          languages.add(language);
          return AudioStream(url: 'https://explode/$id');
        },
      );
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      await engine.resolveAudioStream(url, audioLanguage: 'ko');
      await engine.resolveAudioStream(url);
      expect(languages, ['ko', null]);
    });

    test(
      'YoutubeExplodeEngine: 오디오 언어 목록은 트랙이 둘 이상일 때만 쓰고 아니면 안쪽 엔진에 묻는다',
      () async {
        final inner = FakeDownloaderEngine()
          ..audioLanguages = const [
            AudioLanguage(id: 'en', name: 'English', isDefault: true),
            AudioLanguage(id: 'ko', name: 'Korean'),
          ];
        var tracks = const <AudioLanguage>[
          AudioLanguage(id: 'ja', name: 'Japanese', isDefault: true),
          AudioLanguage(id: 'fr', name: 'French'),
        ];
        final engine = YoutubeExplodeEngine(
          inner,
          languageReader: (_) async => tracks,
        );
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        expect((await engine.fetchAudioLanguages(url)).map((e) => e.id), [
          'ja',
          'fr',
        ]);
        tracks = const [AudioLanguage(id: 'ja', name: 'Japanese')];
        expect((await engine.fetchAudioLanguages(url)).map((e) => e.id), [
          'en',
          'ko',
        ]);
      },
    );

    test('LocalEngine: 오디오 언어 목록은 형식의 language에서 읽고 고른 언어로 받는다', () async {
      final calls = <List<String>>[];
      final engine = LocalEngine(
        run: (_, args) async {
          calls.add(args);
          return (
            exitCode: 0,
            stdout: jsonEncode({
              'url': 'https://rr.googlevideo.com/audio',
              'formats': [
                {'vcodec': 'avc1', 'language': 'en'},
                {
                  'vcodec': 'none',
                  'language': 'en-US',
                  'format_note': 'English (US) original (default), medium',
                },
                {
                  'vcodec': 'none',
                  'language': 'ko',
                  'format_note': 'Korean, medium',
                },
                {
                  'vcodec': 'none',
                  'language': 'ko',
                  'format_note': 'Korean, low',
                },
              ],
            }),
            stderr: '',
          );
        },
      );
      final found = await engine.fetchAudioLanguages('https://x/v');
      expect(found, const [
        AudioLanguage(id: 'en-US', name: 'English (US)', isDefault: true),
        AudioLanguage(id: 'ko', name: 'Korean'),
      ]);
      await engine.resolveAudioStream('https://x/v', audioLanguage: 'ko');
      expect(calls.last, contains(startsWith('bestaudio[language=ko]')));
    });

    test('CachedDownloaderEngine: 오디오 언어마다 따로 기억한다', () async {
      final inner = FakeDownloaderEngine();
      final engine = CachedDownloaderEngine(inner);
      await engine.resolveAudioStream('https://x/v');
      await engine.resolveAudioStream('https://x/v', audioLanguage: 'ko');
      await engine.resolveAudioStream('https://x/v', audioLanguage: 'ko');
      expect(inner.audioLanguageArgs, [null, 'ko']);
    });

    test('audioLanguageId: 트랙 번호를 떼고 언어 코드만 남긴다', () {
      expect(audioLanguageId('en-US.4'), 'en-US');
      expect(audioLanguageId('ko'), 'ko');
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
    test('듣다 소리가 끊기면 멈춘 채 남고, 다시 재생하면 주소를 새로 읽어 다시 튼다', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(info: VideoInfo(_a)), player);
      await cubit.toggle(_a);
      expect(player.played, hasLength(1));

      player.fail('network');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, PreviewStatus.playing);
      expect(cubit.state.paused, isTrue);
      expect(cubit.state.error, isNull);

      await cubit.togglePause();
      expect(player.played, hasLength(2));
      expect(cubit.state.paused, isFalse);
      await cubit.close();
    });

    test('듣기를 시작하면 플레이어에 곡을 적어 둔다', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(info: VideoInfo(_a)), player);
      await cubit.toggle(_a);
      await Future<void>.delayed(Duration.zero);
      expect(player.remembered, [_a]);
      await cubit.close();
    });

    test('앱이 켜질 때 플레이어가 소리를 내고 있으면 미니 플레이어 상태를 되살린다', () async {
      final player = FakePreviewPlayer()
        ..snapshot = const PreviewSnapshot(
          hit: _a,
          position: Duration(seconds: 20),
          duration: Duration(minutes: 2),
          paused: true,
        );
      final cubit = _cubit(FakeDownloaderEngine(info: VideoInfo(_a)), player);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, PreviewStatus.playing);
      expect(cubit.state.hitId, 'a');
      expect(cubit.state.title, 'Song A');
      expect(cubit.state.paused, isTrue);
      expect(cubit.state.fraction, closeTo(1 / 6, .001));
      await cubit.close();
    });

    test('syncWithPlayer: 화면은 듣는 중인데 플레이어가 멈춰 있으면 화면도 멈춘다', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(info: VideoInfo(_a)), player);
      await cubit.toggle(_a);
      expect(cubit.state.status, PreviewStatus.playing);
      await cubit.syncWithPlayer();
      expect(cubit.state.status, PreviewStatus.idle);
      await cubit.close();
    });

    test('syncWithPlayer: 알림에서 멈춘 상태가 화면에도 맞춰진다', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(info: VideoInfo(_a)), player);
      await cubit.toggle(_a);
      player.snapshot = const PreviewSnapshot(
        hit: _a,
        position: Duration(seconds: 5),
        paused: true,
      );
      await cubit.syncWithPlayer();
      expect(cubit.state.status, PreviewStatus.playing);
      expect(cubit.state.paused, isTrue);
      await cubit.close();
    });

    test('재생 위치가 오면 들은 비율이 바뀌고, 멈추면 지워진다', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(info: VideoInfo(_a)), player);
      await cubit.toggle(_a);
      player.progress(const Duration(seconds: 30), const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.fraction, closeTo(.25, .001));
      await cubit.stop();
      expect(cubit.state.progress, isNull);
      await cubit.close();
    });

    test('togglePause: 일시정지와 이어 듣기를 오가고, 위치는 그대로 둔다', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(info: VideoInfo(_a)), player);
      await cubit.togglePause();
      expect(player.pauses, 0);
      await cubit.toggle(_a);
      player.progress(const Duration(seconds: 30), const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
      await cubit.togglePause();
      expect(cubit.state.paused, isTrue);
      expect(cubit.state.status, PreviewStatus.playing);
      expect(player.pauses, 1);
      player.progress(const Duration(seconds: 31), const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.paused, isTrue);
      await cubit.togglePause();
      expect(cubit.state.paused, isFalse);
      expect(player.resumes, 1);
      await cubit.stop();
      expect(cubit.state.paused, isFalse);
      await cubit.close();
    });

    test('seekTo: 길이의 비율 자리로 옮기고, 길이를 모르면 옮기지 않는다', () async {
      final player = FakePreviewPlayer();
      final cubit = _cubit(FakeDownloaderEngine(info: VideoInfo(_a)), player);
      await cubit.toggle(_a);
      await cubit.seekTo(.5);
      expect(player.seeks, isEmpty);
      player.progress(const Duration(seconds: 10), const Duration(minutes: 2));
      await Future<void>.delayed(Duration.zero);
      await cubit.seekTo(.5);
      expect(player.seeks, [const Duration(minutes: 1)]);
      expect(cubit.state.progress?.position, const Duration(minutes: 1));
      expect(cubit.state.hit, _a);
      await cubit.close();
    });

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
      await tester.longPress(find.text('Song').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
    }

    testWidgets('길게 누르기 메뉴에서 미리 듣고, 메뉴나 멈춤 버튼으로 멈춘다', (tester) async {
      final player = await openSearch(tester);
      expect(find.byTooltip('Stop preview'), findsNothing);

      await previewFromMenu(tester);
      expect(player.playing, isTrue);
      expect(find.byTooltip('Stop preview'), findsWidgets);

      await tester.longPress(find.text('Song').first);
      await tester.pumpAndSettle();
      expect(find.text('Stop preview'), findsOneWidget);
      await tester.tap(find.text('Stop preview'));
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
      expect(find.byTooltip('Stop preview'), findsNothing);

      await previewFromMenu(tester);
      await tester.tap(find.byKey(const ValueKey('preview-row-button')));
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

    testWidgets('검색 줄의 미리 듣기 버튼으로 바로 듣고 같은 버튼으로 멈춘다', (tester) async {
      final player = await openSearch(tester);

      await tester.tap(find.byKey(const ValueKey('preview-row-button')));
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);
      expect(find.byKey(const ValueKey('preview-mini-player')), findsOneWidget);
      // 재생 알림이 미리 듣는 곡으로 바뀐다.
      final session = sl<MediaSession>() as FakeMediaSession;
      expect(session.updates.last?.preview, isTrue);

      await tester.tap(find.byKey(const ValueKey('preview-row-button')));
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
      expect(find.byTooltip('Preview'), findsOneWidget);
      expect(find.byKey(const ValueKey('preview-mini-player')), findsNothing);
    });

    testWidgets('듣는 동안 줄과 상세 화면에 재생 진행도가 보인다', (tester) async {
      final player = await openSearch(tester);
      expect(find.byKey(const ValueKey('preview-progress')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('preview-row-button')));
      await tester.pumpAndSettle();
      player.progress(const Duration(seconds: 30), const Duration(minutes: 2));
      await tester.pump();
      expect(find.byKey(const ValueKey('preview-progress')), findsOneWidget);
      // 줄 안 막대 + 아래쪽 미리 듣기 줄의 막대.
      expect(find.byType(ProgressLine), findsNWidgets(2));

      await tester.tap(find.text('Song').first);
      await tester.pumpAndSettle();
      player.progress(const Duration(seconds: 30), const Duration(minutes: 2));
      await tester.pump();
      expect(find.byKey(const ValueKey('preview-position')), findsOneWidget);
      expect(find.text('0:30'), findsWidgets);
      expect(find.text('2:00'), findsWidgets);
    });

    testWidgets('미리 듣는 동안 미니 플레이어가 그 곡으로 바뀌고, 누르면 상세가 열린다', (tester) async {
      await openSearch(tester);
      await tester.tap(find.byKey(const ValueKey('preview-row-button')));
      await tester.pumpAndSettle();

      final bar = find.byKey(const ValueKey('preview-mini-player'));
      expect(bar, findsOneWidget);
      // 넘길 곡이 없어서 이전 · 다음 버튼은 없다.
      expect(find.byTooltip('Previous'), findsNothing);
      expect(find.byTooltip('Next'), findsNothing);

      await tester.tap(
        find.descendant(of: bar, matching: find.byType(Text)).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(MediaDetailScreen), findsOneWidget);
    });

    testWidgets('준비하는 동안 미니 플레이어가 미리 듣는 곡으로 바뀌고, 끝나면 사라진다', (tester) async {
      await openSearch(tester);
      expect(find.byKey(const ValueKey('preview-mini-player')), findsNothing);
      final state = tester
          .element(find.byType(AppBottomNav))
          .read<PreviewCubit>();
      state.emit(
        PreviewState(
          hitId: 'x',
          status: PreviewStatus.loading,
          title: 'T',
          loadStartedAt: DateTime.now(),
          expectedLoad: const Duration(seconds: 5),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const ValueKey('preview-mini-player')), findsOneWidget);
      state.emit(const PreviewState());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('preview-mini-player')), findsNothing);
    });

    testWidgets('상세 화면 버튼으로 미리 듣고, 화면을 나가도 이어진다', (tester) async {
      final player = await openSearch(tester);
      await tester.tap(find.text('Song').first);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(PreviewButton),
          matching: find.text('Preview'),
        ),
      );
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);
      expect(find.text('Stop preview'), findsOneWidget);
      // 일시정지와 멈추기는 따로 있다.
      expect(
        find.byKey(const ValueKey('preview-pause-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('preview-stop-button')), findsOneWidget);

      // 다른 곳에서 잠시 멈춰 두면 상세 화면 버튼도 "이어 듣기"로 바뀌고, 누르면 이어 듣는다.
      await tester
          .element(find.byType(PreviewButton))
          .read<PreviewCubit>()
          .togglePause();
      await tester.pumpAndSettle();
      expect(find.text('Resume preview'), findsOneWidget);
      await tester.tap(find.text('Resume preview'));
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);
      expect(find.text('Stop preview'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);
      expect(find.byKey(const ValueKey('preview-mini-player')), findsOneWidget);

      // 미니 플레이어에서 잠시 멈췄다 이어 듣는다.
      await tester.tap(find.byTooltip('Pause preview'));
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
      expect(find.byKey(const ValueKey('preview-mini-player')), findsOneWidget);
      await tester.tap(find.byTooltip('Resume preview'));
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);

      // 멈추기는 끝낸다.
      await tester.tap(find.byTooltip('Stop preview').last);
      await tester.pumpAndSettle();
      expect(player.playing, isFalse);
      expect(find.byKey(const ValueKey('preview-mini-player')), findsNothing);
    });

    testWidgets('다른 탭으로 가도 이어진다', (tester) async {
      final player = await openSearch(tester);
      await previewFromMenu(tester);
      expect(player.playing, isTrue);

      await tester.tap(find.byKey(const ValueKey('nav-Home')));
      await tester.pumpAndSettle();
      expect(player.playing, isTrue);
      expect(find.byKey(const ValueKey('preview-mini-player')), findsOneWidget);
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
