import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/sync_draft.dart';
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

    test('줄을 묶으면 묶음 하나가 한 번에 찍히고 공백으로 이어진다', () {
      final d = SyncDraft.from(plain, group: 2);
      expect(d.texts, ['첫 줄 둘째 줄', '셋째 줄']);
      final done = d
          .stamp(const Duration(seconds: 1))
          .stamp(const Duration(seconds: 5));
      expect(done.toLrc(), '[00:01.00]첫 줄 둘째 줄\n[00:05.00]셋째 줄');
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

    final player = tester.element(find.text('가 줄')).read<NowPlayingCubit>();
    expect(player.state.track?.id, 't1');
    expect(player.state.isPlaying, isTrue);

    player.seekTo(const Duration(seconds: 3));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('00:03.00'), findsOneWidget);

    // 찍은 줄을 눌러 +0.5초 조정
    await tester.tap(find.text('+0.5s'));
    await tester.pumpAndSettle();
    expect(find.text('00:03.50'), findsOneWidget);

    player.seekTo(const Duration(seconds: 10));
    await tester.pump();
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('2/2줄'), findsOneWidget);

    await tester.tap(find.byTooltip('싱크 저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved['t1'], '[00:03.50]가 줄\n[00:10.00]나 줄');
    expect(find.text('가사를 저장했어요'), findsOneWidget);
  });

  testWidgets('싱크 설정: 묶을 줄 수를 정하면 한 번에 찍는 단위가 바뀐다', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final lyrics = MemoryLyricsRepository(
      sibling: {'t1': '가 줄\n나 줄\n다 줄\n라 줄'},
    );
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
    expect(find.text('0/4줄'), findsOneWidget);

    await tester.tap(find.text('2줄'));
    await tester.pumpAndSettle();
    expect(find.text('0/2줄'), findsOneWidget);
    expect(find.text('가 줄 나 줄'), findsOneWidget);

    // 찍기 시작하면 묶음 줄 수는 더 못 바꾼다.
    await tester.tap(find.text('지금'));
    await tester.pumpAndSettle();
    expect(find.text('2줄'), findsNothing);
  });
}
