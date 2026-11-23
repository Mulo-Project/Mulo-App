import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/presentation/bloc/lyrics_sync_cubit.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';
import 'package:music_download_play_app/features/player/presentation/screens/player_screen.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String title) => Track(
  id: id,
  title: title,
  artist: '가수',
  album: '앨범',
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, 1),
);

void main() {
  test('고른 범위를 한 칸으로 묶고 풀 수 있다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다\n라')!)
      ..stamp(const Duration(seconds: 1));
    cubit.mergeRange(1, 3);
    expect(cubit.state.draft.texts, ['가', '나\n다\n라']);
    expect(cubit.state.draft.current, 1);
    expect(cubit.isMerged(1), isTrue);
    cubit.split(1);
    expect(cubit.state.draft.texts, ['가', '나', '다', '라']);
    expect(cubit.state.draft.current, 1);
  });

  test('찍힌 묶음을 풀면 나뉜 줄이 같은 시간을 가진 채 남고 뒤 싱크와 공백이 생기지 않는다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다\n라')!)
      ..mergeRange(0, 2)
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 6));
    expect(cubit.state.draft.texts, ['가\n나\n다', '라']);
    cubit.split(0);
    expect(cubit.state.draft.texts, ['가', '나', '다', '라']);
    expect(cubit.state.draft.times, [
      const Duration(seconds: 2),
      const Duration(seconds: 2),
      const Duration(seconds: 2),
      const Duration(seconds: 6),
    ]);
    expect(cubit.state.draft.isComplete, isTrue);
  });

  test('찍은 줄을 누르면 값은 그대로이고 그 칸이 다시 찍을 차례가 되며, 지금을 눌러야 그 칸이 바뀐다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다')!)
      ..stamp(const Duration(seconds: 1))
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 3));
    cubit.select(1);
    expect(cubit.state.selected, 1);
    expect(cubit.state.draft.current, 1);
    expect(cubit.state.draft.times, [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 3),
    ]);
    cubit.stamp(const Duration(seconds: 2, milliseconds: 500));
    // 찍으면 자동으로 다음 칸이 찍을 차례가 되고 포커스도 거기로 넘어간다 (포커스 = 찍을 칸)
    expect(cubit.state.draft.current, 2);
    expect(cubit.state.selected, 2);
    expect(cubit.state.draft.times, [
      const Duration(seconds: 1),
      const Duration(seconds: 2, milliseconds: 500),
      const Duration(seconds: 3),
    ]);
  });

  test('앞으로 당겨 찍어 앞의 싱크가 내려오면 바뀐 것 중 맨 앞 칸을 포커스한다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다\n라')!)
      ..stamp(const Duration(seconds: 5))
      ..stamp(const Duration(seconds: 8))
      ..stamp(const Duration(seconds: 12));
    cubit.select(2);
    cubit.stamp(const Duration(seconds: 3));
    expect(cubit.state.draft.times, [
      const Duration(seconds: 3),
      const Duration(seconds: 3),
      const Duration(seconds: 3),
      null,
    ]);
    expect(cubit.state.selected, 0);
    expect(cubit.state.draft.current, 0);
  });

  test('지금으로 다시 찍을 때 뒤에 있던 더 이른 싱크는 새 시간으로 올라가고 되돌리기로 복구된다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다\n라')!)
      ..stamp(const Duration(seconds: 1))
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 3))
      ..stamp(const Duration(seconds: 10));
    cubit.rewindTo(0);
    cubit.stamp(const Duration(seconds: 5));
    expect(cubit.state.draft.times, [
      const Duration(seconds: 1),
      const Duration(seconds: 5),
      null,
      null,
    ]);
    // SyncDraft 단계에서도 뒤에 남은 싱크가 있으면 순서를 유지한다
    final d = SyncDraft.from(Lyrics.parse('가\n나\n다')!)
        .stamp(const Duration(seconds: 1))
        .stamp(const Duration(seconds: 2))
        .stamp(const Duration(seconds: 3))
        .moveTo(1)
        .stamp(const Duration(seconds: 5));
    expect(d.times, [
      const Duration(seconds: 1),
      const Duration(seconds: 5),
      const Duration(seconds: 5),
    ]);
    expect(d.undo().times[2], const Duration(seconds: 3));
  });

  test('뒤로(stepBack)는 가장 뒤에 찍은 싱크를 하나씩 지우고 되돌리기로 복구된다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다')!)
      ..stamp(const Duration(seconds: 1))
      ..stamp(const Duration(seconds: 2));
    cubit.stepBack();
    expect(cubit.state.draft.times, [const Duration(seconds: 1), null, null]);
    expect(cubit.state.draft.current, 1);
    cubit.stepBack();
    expect(cubit.state.draft.stamped, 0);
    expect(cubit.state.draft.current, 0);
    cubit.undo();
    expect(cubit.state.draft.times[0], const Duration(seconds: 1));
  });

  test('같은 시간에 지금을 또 눌러도 칸은 합쳐지지 않고 줄마다 따로 남는다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다\n라')!)
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 2));
    expect(cubit.state.draft.texts, ['가', '나', '다', '라']);
    expect(cubit.state.draft.isComplete, isTrue);
    // 저장하면 줄마다 같은 시간이 붙는다.
    expect(cubit.state.draft.toLrc().split('\n'), hasLength(4));
  });

  test('싱크를 하나라도 찍은 뒤에는 안 찍은 줄 중 맨 앞 칸으로만 돌아갈 수 있다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다\n라\n마')!)
      ..stamp(const Duration(seconds: 1))
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 3));
    cubit.select(0);
    expect(cubit.state.selected, 0);
    expect(cubit.state.draft.current, 0);
    cubit.select(4);
    expect(cubit.state.draft.current, 0);
    cubit.select(3);
    expect(cubit.state.draft.current, 3);
    expect(cubit.state.draft.texts, ['가', '나', '다', '라', '마']);
  });

  test('아직 아무것도 안 찍었으면 아무 줄에서나 시작하고, 첫 싱크가 맨 앞 줄부터 그 줄까지를 묶는다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다\n라')!);
    cubit.select(2);
    expect(cubit.state.draft.current, 2);
    cubit.stamp(const Duration(seconds: 4));
    expect(cubit.state.draft.texts, ['가\n나\n다', '라']);
    expect(cubit.state.draft.times, [const Duration(seconds: 4), null]);
    expect(cubit.state.draft.current, 1);
  });

  test('범위 안에 이미 찍어 둔 싱크가 있을 때만 사라진다고 알아챈다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('a\nb\nc\nd\ne')!)
      ..stamp(const Duration(seconds: 1))
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 3));
    expect(cubit.rangeErasesStamped(0, 2), isTrue);
    expect(cubit.rangeErasesStamped(3, 4), isFalse);
  });

  test('묶인 칸을 펼쳐 한 줄의 시간을 바꾸면 그 줄만 따로 남고, 영역 밖을 누르면 같은 시간끼리 다시 합쳐진다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('a\nb\nc\nd')!)
      ..stamp(const Duration(seconds: 1))
      ..mergeRange(1, 3)
      ..stamp(const Duration(seconds: 5));
    // 칸: [a] [b c d]
    expect(cubit.state.draft.texts, ['a', 'b\nc\nd']);

    cubit.expand(1);
    expect(cubit.state.draft.texts, ['a', 'b', 'c', 'd']);
    expect(cubit.state.expanded, (1, 3));
    expect(
      cubit.state.draft.times.skip(1),
      everyElement(const Duration(seconds: 5)),
    );

    // 같은 시간인 이웃에 막혀 먼저 못 가고(이웃은 함께 움직이지 않는다), 뒤쪽 줄부터 옮긴다
    cubit.select(2);
    cubit.nudge(const Duration(milliseconds: 500));
    expect(cubit.state.draft.times[2], const Duration(seconds: 5));
    cubit.select(3);
    cubit.nudge(const Duration(seconds: 1));
    cubit.select(2);
    cubit.nudge(const Duration(milliseconds: 500));
    expect(cubit.state.expanded, (1, 3));
    expect(cubit.state.draft.times[2], const Duration(milliseconds: 5500));
    expect(cubit.state.draft.times[3], const Duration(seconds: 6));

    // 영역 밖(첫 칸)을 누르면 접히고, 시간이 달라진 줄은 따로 남는다
    cubit.select(0);
    expect(cubit.state.expanded, isNull);
    expect(cubit.state.draft.texts, ['a', 'b', 'c', 'd']);
  });

  test('펼친 줄의 시간이 그대로면 영역 밖을 누를 때 원래대로 합쳐진다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('a\nb\nc\nd')!)
      ..stamp(const Duration(seconds: 1))
      ..mergeRange(1, 3)
      ..stamp(const Duration(seconds: 5))
      ..expand(1)
      ..select(0);
    expect(cubit.state.expanded, isNull);
    expect(cubit.state.draft.texts, ['a', 'b\nc\nd']);
  });

  test('찍힌 칸끼리도 범위로 합칠 수 있고 앞 칸의 시간을 쓴다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다')!)
      ..stamp(const Duration(seconds: 1))
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 3));
    cubit.mergeRange(0, 1);
    expect(cubit.state.draft.texts, ['가\n나', '다']);
    expect(cubit.state.draft.times, [
      const Duration(seconds: 1),
      const Duration(seconds: 3),
    ]);
    expect(cubit.state.draft.isComplete, isTrue);
  });

  group('SyncDraft', () {
    final plain = Lyrics.parse('첫 줄\n\n둘째 줄\n셋째 줄')!;

    test('빈 줄은 빼고 줄을 만든다', () {
      final d = SyncDraft.from(plain);
      expect(d.texts, ['첫 줄', '둘째 줄', '셋째 줄']);
      expect(d.stamped, 0);
    });

    test('찍으면 다음 줄로 넘어가고, 모두 찍으면 LRC가 된다', () {
      var d = SyncDraft.from(plain)
          .stamp(const Duration(seconds: 1, milliseconds: 230))
          .stamp(const Duration(seconds: 65, milliseconds: 5))
          .stamp(const Duration(minutes: 2));
      expect(d.isComplete, isTrue);
      expect(d.current, 3);
      expect(d.stamp(const Duration(minutes: 3)), d);
      expect(d.toLrc(), '[00:01.23]첫 줄\n[01:05.01]둘째 줄\n[02:00.00]셋째 줄');
      // 만든 LRC를 다시 읽으면 싱크 가사
      expect(Lyrics.parse(d.toLrc())!.isSynced, isTrue);
    });

    test('시간 조정은 0 아래로 내려가지 않고, 안 찍은 줄은 무시한다', () {
      final d = SyncDraft.from(plain).stamp(const Duration(milliseconds: 200));
      expect(
        d.nudge(0, const Duration(milliseconds: -500)).times[0],
        Duration.zero,
      );
      expect(
        d.nudge(0, const Duration(milliseconds: 100)).times[0],
        const Duration(milliseconds: 300),
      );
      expect(d.nudge(2, const Duration(seconds: 1)), d);
    });

    test('시간 조정은 앞뒤 이웃 싱크의 시간을 넘지 않고 이웃은 움직이지 않는다', () {
      final d = SyncDraft.from(plain)
          .stamp(const Duration(seconds: 2))
          .stamp(const Duration(seconds: 4))
          .stamp(const Duration(seconds: 6));
      expect(
        d.nudge(1, const Duration(seconds: 10)).times[1],
        const Duration(seconds: 6),
      );
      expect(
        d.nudge(1, const Duration(seconds: -10)).times[1],
        const Duration(seconds: 2),
      );
      expect(
        d.nudge(0, const Duration(seconds: 10)).times[0],
        const Duration(seconds: 4),
      );
    });

    test('앞 싱크보다 이른 위치에서 찍으면 앞에 있던 더 늦은 싱크가 그 시간까지 내려온다', () {
      final d = SyncDraft.from(plain)
          .stamp(const Duration(seconds: 5))
          .stamp(const Duration(seconds: 3));
      expect(d.times[0], const Duration(seconds: 3));
      expect(d.times[1], const Duration(seconds: 3));
      expect(d.undo().times[0], const Duration(seconds: 5));
    });

    test('되돌리기는 찍기와 조정을 차례로 취소한다', () {
      final d = SyncDraft.from(plain)
          .stamp(const Duration(seconds: 1))
          .nudge(0, const Duration(milliseconds: 500));
      final back = d.undo();
      expect(back.times[0], const Duration(seconds: 1));
      final first = back.undo();
      expect(first.stamped, 0);
      expect(first.current, 0);
      expect(first.canUndo, isFalse);
    });

    test('이 싱크로: 그 줄까지만 남기고 뒤는 등록을 푼다', () {
      final d = SyncDraft.from(plain)
          .stamp(const Duration(seconds: 1))
          .stamp(const Duration(seconds: 2))
          .stamp(const Duration(seconds: 3))
          .rewindTo(0);
      expect(d.times, [const Duration(seconds: 1), null, null]);
      expect(d.current, 1);
      expect(d.undo().stamped, 3);
    });

    test('도중 저장은 찍은 줄까지만 시간을 붙이고, 이어서 찍을 수 있다', () {
      final d = SyncDraft.from(plain).stamp(const Duration(seconds: 1));
      final lrc = d.toPartialLrc();
      expect(lrc, '[00:01.00]첫 줄\n둘째 줄\n셋째 줄');
      final saved = Lyrics.parse(lrc)!;
      expect(saved.lines.length, 1);
      final resumed = SyncDraft.from(saved);
      expect(resumed.texts, ['첫 줄', '둘째 줄', '셋째 줄']);
      expect(resumed.current, 1);
      expect(resumed.stamped, 1);
    });

    test('시간이 붙은 txt도 싱크 가사로 읽는다', () {
      expect(Lyrics.parse('[00:01.00]가\n[00:02.50]나')!.isSynced, isTrue);
    });

    test('줄을 묶으면 묶음 하나가 한 번에 찍히고 줄은 그대로 같은 시간이 붙는다', () {
      final d = SyncDraft.from(plain, group: 2);
      expect(d.texts, ['첫 줄\n둘째 줄', '셋째 줄']);
      final done = d
          .stamp(const Duration(seconds: 1))
          .stamp(const Duration(seconds: 5));
      expect(done.toLrc(), '[00:01.00]첫 줄\n[00:01.00]둘째 줄\n[00:05.00]셋째 줄');
    });

    test('한 칸만 다시 묶으면 남는 줄은 기본 줄 수로 다시 나뉘고 시간은 지워진다', () {
      final lyrics = Lyrics.parse('가\n나\n다\n라\n마')!;
      final d = SyncDraft.from(lyrics).stamp(const Duration(seconds: 1));
      final three = d.regroup(0, 2);
      expect(three.texts, ['가\n나\n다', '라', '마']);
      expect(three.stamped, 0);
      expect(three.current, 0);
      // 줄이면 남는 줄이 기본 줄 수 칸으로, 늘리면 삼킨 칸은 사라진다.
      expect(three.regroup(0, 0, group: 2).texts, ['가', '나\n다', '라', '마']);
      expect(three.regroup(1, 4).texts, ['가\n나\n다', '라\n마']);
      expect(three.isCustom(1), isTrue);
      expect(SyncDraft.from(lyrics, group: 2).isCustom(2), isFalse);
    });

    test('이미 싱크된 가사는 시간을 이어받는다', () {
      final d = SyncDraft.from(Lyrics.parse('[00:01.00]가\n[00:02.00]나')!);
      expect(d.isComplete, isTrue);
      expect(d.times[1], const Duration(seconds: 2));
    });
  });

  testWidgets('가사 화면 › 싱크 설정: 지금을 눌러 찍고 저장하면 싱크 가사로 저장된다', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final lyrics = MemoryLyricsRepository(sibling: {'t1': '가 줄\n나 줄'});
    await setUpTestDependencies(tracks: [_t('t1', '첫 곡')], lyrics: lyrics);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    tester.element(find.byType(PlayerScreen)).read<NowPlayingCubit>().playQueue(
      [_t('t1', '첫 곡')],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('싱크 설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final player = tester.element(find.text('가 줄')).read<NowPlayingCubit>();
    expect(player.state.track?.id, 't1');
    // 들어오면 멈춘 채 처음(0초)에 서 있다
    expect(player.state.isPlaying, isFalse);
    expect(player.state.position, Duration.zero);

    player.togglePlay();
    player.seekTo(const Duration(seconds: 30));
    await tester.pump();
    await tester.tap(find.byTooltip('0.5초 전으로 (길게 눌러 단위 바꾸기)'));
    await tester.pump();
    expect(player.state.position, const Duration(milliseconds: 29500));

    player.seekTo(const Duration(seconds: 3));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('00:03.00'), findsOneWidget);

    // 찍은 줄을 눌러 +0.5초 조정 (찍으면 포커스가 다음 칸으로 가므로 먼저 그 줄을 누른다)
    await tester.tap(find.text('00:03.00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+0.5s').first);
    await tester.pumpAndSettle();
    expect(find.text('00:03.50'), findsOneWidget);
    expect(
      player.state.position,
      const Duration(seconds: 3, milliseconds: 500),
    );

    // 이어 찍을 빈 칸을 눌러 포커스한 뒤 찍는다
    await tester.tap(find.text('이어 찍기'));
    await tester.pumpAndSettle();
    player.seekTo(const Duration(seconds: 10));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('2/2줄'), findsOneWidget);

    // 찍은 줄을 누르면 재생 위치도 그 싱크로 옮겨진다
    await tester.tap(find.text('00:03.50'));
    await tester.pumpAndSettle();
    expect(
      player.state.position,
      const Duration(seconds: 3, milliseconds: 500),
    );

    // 자동 멈춤: 다음 줄의 기존 싱크(10초)에 닿으면 멈춘다
    await tester.tap(find.byTooltip('다음 줄에 이미 있는 싱크 시간에 닿으면 재생을 멈춰요'));
    await tester.pump();
    if (!player.state.isPlaying) player.togglePlay();
    player.seekTo(const Duration(seconds: 10));
    await tester.pump();
    expect(player.state.isPlaying, isFalse);

    // 멈춘 자리에서 앞으로는 못 가고, 뒤로 가면 다시 재생된다
    await tester.tap(find.text('+0.5s').last);
    await tester.pump();
    expect(player.state.position, const Duration(seconds: 10));
    await tester.tap(find.text('−0.5s').last);
    await tester.pump();
    expect(
      player.state.position,
      const Duration(seconds: 9, milliseconds: 500),
    );
    expect(player.state.isPlaying, isTrue);

    // 찍은 줄을 누르면 그 칸이 다시 찍을 차례가 되어, 지금을 누르면 그 칸이 새 시간으로 바뀐다
    await tester.tap(find.text('00:10.00'));
    await tester.pumpAndSettle();
    player.seekTo(const Duration(seconds: 12));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('00:12.00'), findsOneWidget);

    await tester.tap(find.byTooltip('싱크 저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved['t1'], '[00:03.50]가 줄\n[00:12.00]나 줄');
    expect(find.text('가사를 저장했어요'), findsNothing); // 화면이 닫히므로 안내는 없다
  });

  Future<void> dragMerge(WidgetTester tester, String from, String to) async {
    final g = await tester.startGesture(tester.getCenter(find.text(from)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await g.moveTo(tester.getCenter(find.text(to)));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
  }

  Future<MemoryLyricsRepository> openSync(
    WidgetTester tester,
    String text,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final lyrics = MemoryLyricsRepository(sibling: {'t1': text});
    await setUpTestDependencies(tracks: [_t('t1', '첫 곡')], lyrics: lyrics);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    tester.element(find.byType(PlayerScreen)).read<NowPlayingCubit>().playQueue(
      [_t('t1', '첫 곡')],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('싱크 설정'));
    await tester.pumpAndSettle();
    return lyrics;
  }

  testWidgets('싱크 설정: 처음 들어가면 기본 줄 수를 묻고, 위쪽 메뉴로 바꾸면 경고한다', (tester) async {
    await openSync(tester, '가 줄\n나 줄\n다 줄\n라 줄');
    expect(find.text('한 번에 묶을 줄 수'), findsOneWidget);
    await tester.tap(find.text('2줄'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('0/2줄'), findsOneWidget);
    expect(find.text('가 줄\n나 줄'), findsOneWidget);

    // 찍은 시간이 있으면 바꾸기 전에 경고한다. 취소하면 그대로.
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('기본 줄 수 변경'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1줄').last);
    await tester.pumpAndSettle();
    expect(find.text('묶음이 사라져요'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('1/2줄'), findsOneWidget);

    await tester.tap(find.byTooltip('기본 줄 수 변경'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1줄').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('바꾸기'));
    await tester.pumpAndSettle();
    expect(find.text('0/4줄'), findsOneWidget);
  });

  testWidgets('싱크 설정: 위쪽 메뉴에 기본 줄 수와 반응 시간 보정이 함께 있다', (tester) async {
    await openSync(tester, '가 줄\n나 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('기본 줄 수 변경'));
    await tester.pumpAndSettle();
    expect(find.text('1줄'), findsWidgets);
    await tester.tap(find.text('반응 시간 보정').last);
    await tester.pumpAndSettle();
    expect(find.text('박자 테스트'), findsOneWidget);
  });

  testWidgets('싱크 설정: 꾹 눌러 끌면 범위가 한 칸으로 묶여 표시되고 풀 수 있다', (tester) async {
    await openSync(tester, '가 줄\n나 줄\n다 줄\n라 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('0/4줄'), findsOneWidget);

    await dragMerge(tester, '가 줄', '다 줄');
    expect(find.text('0/2줄'), findsOneWidget);
    expect(find.text('가 줄\n나 줄\n다 줄'), findsOneWidget);
    expect(find.text('3줄 같은 시간으로 묶음'), findsOneWidget);

    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('1/2줄'), findsOneWidget);

    // 찍힌 칸을 풀면 나뉜 줄들이 같은 시간을 가진 채 남아 공백이 생기지 않는다
    await tester.tap(find.text('풀기'));
    await tester.pumpAndSettle();
    expect(find.text('3/4줄'), findsOneWidget);
    expect(find.text('3줄 같은 시간으로 묶음'), findsNothing);
  });

  testWidgets('싱크 설정: 시간이 같은 이웃 줄도 다시 열 때 묶지 않고 줄마다 보인다', (tester) async {
    await openSync(tester, '[00:01.00]가 줄\n[00:01.00]나 줄\n[00:03.00]다 줄');
    expect(find.text('3/3줄'), findsOneWidget);
    expect(find.text('2줄 같은 시간으로 묶음'), findsNothing);
  });

  testWidgets('싱크 설정: 이미 싱크가 있는 가사도 꾹 눌러 끌어 묶고 풀 수 있다', (tester) async {
    final lyrics = await openSync(
      tester,
      '[00:01.00]가 줄\n[00:02.00]나 줄\n[00:03.00]다 줄\n[00:04.00]라 줄',
    );
    expect(find.text('4/4줄'), findsOneWidget);

    await dragMerge(tester, '가 줄', '다 줄');
    // 이미 찍어 둔 싱크가 지워지니 먼저 묻는다.
    expect(
      find.text('묶을 범위 안에 이미 찍어 둔 싱크가 있어요. 한 칸으로 묶으면 그 싱크는 지워져요. 계속할까요?'),
      findsOneWidget,
    );
    await tester.tap(find.text('묶기'));
    await tester.pumpAndSettle();
    expect(find.text('가 줄\n나 줄\n다 줄'), findsOneWidget);
    // 묶은 칸은 맨 앞 칸의 시간을 쓰고 나머지 시간은 사라진다.
    expect(find.text('2/2줄'), findsOneWidget);
    expect(find.text('3줄 같은 시간으로 묶음'), findsOneWidget);

    await tester.tap(find.text('풀기'));
    await tester.pumpAndSettle();
    expect(find.text('4/4줄'), findsOneWidget);
    expect(lyrics.saved, isEmpty);
  });

  testWidgets('싱크 설정: 위로 끌어도 범위가 한 칸으로 묶인다', (tester) async {
    await openSync(tester, '가 줄\n나 줄\n다 줄\n라 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await dragMerge(tester, '다 줄', '가 줄');
    expect(find.text('가 줄\n나 줄\n다 줄'), findsOneWidget);
    expect(find.text('0/2줄'), findsOneWidget);
  });

  testWidgets('싱크 설정: 묶인 칸을 꾹 누르면 줄별로 펼쳐지고 영역 밖을 누르면 접힌다', (tester) async {
    await openSync(tester, '가 줄\n나 줄\n다 줄\n라 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await dragMerge(tester, '가 줄', '다 줄');
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('가 줄\n나 줄\n다 줄'), findsOneWidget);

    await tester.longPress(find.text('가 줄\n나 줄\n다 줄'));
    await tester.pumpAndSettle();
    expect(find.text('가 줄'), findsOneWidget);
    expect(find.text('나 줄'), findsOneWidget);
    expect(find.text('다 줄'), findsOneWidget);
    expect(find.textContaining('줄별로 펼쳤어요'), findsOneWidget);

    await tester.tap(find.text('라 줄'));
    await tester.pumpAndSettle();
    expect(find.textContaining('줄별로 펼쳤어요'), findsNothing);
    expect(find.text('가 줄\n나 줄\n다 줄'), findsOneWidget);
  });

  testWidgets('싱크 설정: 뒤에 싱크가 있는 칸을 고르면 이 싱크로 초기화가 보이고 누르면 그 싱크로 초기화된다', (
    tester,
  ) async {
    await openSync(tester, '가 줄\n나 줄\n다 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    final player = tester.element(find.text('가 줄')).read<NowPlayingCubit>();
    player.seekTo(const Duration(seconds: 2));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    player.seekTo(const Duration(seconds: 6));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    // 가장 뒤에 찍은 칸이 선택돼 있어 취소할 뒤 싱크가 없다
    expect(find.text('이 싱크로 초기화'), findsNothing);

    // 앞쪽 칸을 고르면 취소하기가 나오고, 누르면 그 싱크로 초기화된다
    await tester.tap(find.text('00:02.00'));
    await tester.pumpAndSettle();
    expect(find.text('이 싱크로 초기화'), findsOneWidget);
    await tester.tap(find.text('이 싱크로 초기화'));
    await tester.pumpAndSettle();
    expect(find.text('1/3줄'), findsOneWidget);
    expect(find.text('이어 찍기'), findsOneWidget);
    expect(find.text('--:--.--'), findsOneWidget);
  });

  testWidgets('싱크 설정: 뒤로 버튼은 가장 뒤에 찍은 싱크를 한 칸씩 지우고 그 앞에서 다시 들려준다', (
    tester,
  ) async {
    await openSync(tester, '가 줄\n나 줄\n다 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    final player = tester.element(find.text('가 줄')).read<NowPlayingCubit>();

    player.seekTo(const Duration(seconds: 2));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    player.seekTo(const Duration(seconds: 6));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('2/3줄'), findsOneWidget);

    await tester.tap(find.byTooltip('싱크 한 칸 지우고 뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('1/3줄'), findsOneWidget);
    expect(player.state.position, const Duration(seconds: 4));
    expect(player.state.isPlaying, isTrue);

    await tester.tap(find.byTooltip('싱크 한 칸 지우고 뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('0/3줄'), findsOneWidget);
  });

  testWidgets('싱크 설정: 중간 저장한 가사를 다시 열면 마지막 싱크 위치에 재생이 맞춰진다', (tester) async {
    await openSync(tester, '[00:04.00]가 줄\n[00:09.00]나 줄\n다 줄');
    await tester.pumpAndSettle();
    final player = tester.element(find.text('가 줄')).read<NowPlayingCubit>();
    expect(player.state.position, const Duration(seconds: 9));
    expect(player.state.isPlaying, isFalse);
  });

  testWidgets('싱크 설정: 덜 찍어도 저장 버튼을 누르면 찍은 곳까지 중간 저장된다', (tester) async {
    final lyrics = await openSync(tester, '가 줄\n나 줄\n다 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    // 하나도 안 찍었을 때는 저장 버튼이 눌리지 않는다 (아래에서 하나 찍은 뒤 누른다)
    expect(find.byTooltip('중간 저장 (찍은 곳까지)'), findsOneWidget);

    final player = tester.element(find.text('가 줄')).read<NowPlayingCubit>();
    player.seekTo(const Duration(seconds: 2));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('중간 저장 (찍은 곳까지)'));
    await tester.pumpAndSettle();
    expect(lyrics.saved['t1'], '[00:02.00]가 줄\n나 줄\n다 줄');
  });

  testWidgets('싱크 설정: 지금으로 이미 싱크된 칸으로 넘어가면 재생도 그 싱크 위치로 맞춰진다', (tester) async {
    await openSync(tester, '가 줄\n나 줄\n다 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    final player = tester.element(find.text('가 줄')).read<NowPlayingCubit>();
    player.seekTo(const Duration(seconds: 2));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    player.seekTo(const Duration(seconds: 8));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();

    // 첫 칸을 눌러 다시 찍으면 포커스가 이미 싱크된 둘째 칸(8초)으로 넘어가고 재생도 거기로 간다
    await tester.tap(find.text('00:02.00'));
    await tester.pumpAndSettle();
    player.seekTo(const Duration(seconds: 1));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(player.state.position, const Duration(seconds: 8));

    // 다음이 빈 칸이면 재생 위치는 그대로다
    await tester.tap(find.text('00:08.00'));
    await tester.pumpAndSettle();
    player.seekTo(const Duration(seconds: 9));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(player.state.position, const Duration(seconds: 9));
  });

  testWidgets('싱크 설정: 재생 시간이 슬라이더 아래, 지금 버튼 위에 보인다', (tester) async {
    await openSync(tester, '가 줄\n나 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    final clock = find.textContaining(' / ');
    expect(clock, findsOneWidget);
    expect(
      tester.getTopLeft(clock).dy,
      lessThan(tester.getTopLeft(find.text('지금')).dy),
    );
    expect(
      tester.getTopLeft(clock).dy,
      greaterThan(tester.getTopLeft(find.text('가 줄')).dy),
    );
  });
}
