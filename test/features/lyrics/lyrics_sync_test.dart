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
  test('안 찍은 뒤쪽 줄을 누르면 건너뛴 줄들이 그 줄과 한 칸으로 묶인다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다\n라')!)
      ..stamp(const Duration(seconds: 1));
    cubit.select(3);
    expect(cubit.state.draft.texts, ['가', '나\n다\n라']);
    expect(cubit.state.draft.current, 1);
    expect(cubit.isMerged(1), isTrue);
    cubit.split(1);
    expect(cubit.state.draft.texts, ['가', '나', '다', '라']);
    expect(cubit.state.draft.current, 1);
  });

  test('같은 시간에 지금을 또 누르면 직전 줄과 한 칸으로 묶인다', () {
    final cubit = LyricsSyncCubit(Lyrics.parse('가\n나\n다')!)
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 2))
      ..stamp(const Duration(seconds: 5));
    expect(cubit.state.draft.texts, ['가\n나', '다']);
    expect(cubit.state.draft.times, [
      const Duration(seconds: 2),
      const Duration(seconds: 5),
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

    // 찍은 줄을 눌러 +0.5초 조정
    await tester.tap(find.text('+0.5s').first);
    await tester.pumpAndSettle();
    expect(find.text('00:03.50'), findsOneWidget);
    expect(
      player.state.position,
      const Duration(seconds: 3, milliseconds: 500),
    );

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

    // 뒤쪽 줄을 골라 지금을 누르면 다음 줄의 싱크가 덮어써진다
    player.seekTo(const Duration(seconds: 12));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('00:12.00'), findsOneWidget);

    await tester.tap(find.byTooltip('싱크 저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved['t1'], '[00:03.50]가 줄\n[00:12.00]나 줄');
    expect(find.text('가사를 저장했어요'), findsOneWidget);
  });

  Future<void> openSync(WidgetTester tester, String text) async {
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

  testWidgets('싱크 설정: 줄을 건너뛰면 한 칸으로 묶여 표시되고 풀 수 있다', (tester) async {
    await openSync(tester, '가 줄\n나 줄\n다 줄\n라 줄');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('0/4줄'), findsOneWidget);

    await tester.tap(find.text('다 줄'));
    await tester.pumpAndSettle();
    expect(find.text('0/2줄'), findsOneWidget);
    expect(find.text('가 줄\n나 줄\n다 줄'), findsOneWidget);
    expect(find.text('3줄 같은 시간으로 묶음'), findsOneWidget);

    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('1/2줄'), findsOneWidget);

    await tester.tap(find.text('풀기'));
    await tester.pumpAndSettle();
    expect(find.text('0/4줄'), findsOneWidget);
    expect(find.text('3줄 같은 시간으로 묶음'), findsNothing);
  });

  testWidgets('싱크 설정: 이전 싱크로 버튼은 완료한 싱크를 한 칸씩 거슬러 포커스한다', (tester) async {
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

    await tester.tap(find.byTooltip('이전 싱크로'));
    await tester.pumpAndSettle();
    expect(player.state.position, const Duration(seconds: 2));
    expect(find.text('+0.1s'), findsWidgets);
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
