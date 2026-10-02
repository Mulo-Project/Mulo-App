import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/player/domain/usecases/player_style_usecases.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/player_style_cubit.dart';
import 'package:music_download_play_app/features/player/presentation/widgets/player_common.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String title) => Track(
  id: id,
  title: title,
  artist: '가수',
  album: '앨범',
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

Future<void> _openPlayer(WidgetTester tester, PlayerStyle style) async {
  await setUpTestDependencies(
    tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡')],
    playerStyle: style,
  );
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.localesTestValue = const [Locale('ko')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
  await tester.pumpAndSettle();
  await tester.tap(find.text('첫 곡'));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).push(Routes.player);
  await tester.pumpAndSettle();
}

void main() {
  test('플레이어 모양을 고르면 저장하고, 다시 불러온다', () async {
    final repo = MemoryPlayerStyleRepository();
    PlayerStyleCubit make() => PlayerStyleCubit(
      loadStyle: LoadPlayerStyle(repo),
      saveStyle: SavePlayerStyle(repo),
    );
    final a = make();
    addTearDown(a.close);
    expect(a.state, PlayerStyle.square);
    await a.select(PlayerStyle.custom);
    expect(repo.style, PlayerStyle.custom);

    final b = make();
    addTearDown(b.close);
    await b.load();
    expect(b.state, PlayerStyle.custom);
  });

  test('진행 막대 윤곽 위 가장 가까운 점을 0~1로 바꾼다', () {
    final points = [for (var i = 0; i <= 100; i++) Offset(i.toDouble(), 0)];
    final (a, d) = MorphSeek.nearest(points, const Offset(25, 3));
    expect(a, closeTo(.25, .001));
    expect(d, closeTo(3, .001));
    expect(MorphSeek.nearest(points, const Offset(500, 0)).$1, 1);
  });

  for (final style in PlayerStyle.values) {
    testWidgets('${style.name} 모양 플레이어: 곡 정보와 조작이 모두 있다', (tester) async {
      await _openPlayer(tester, style);

      expect(find.text('첫 곡'), findsWidgets);
      expect(find.byTooltip('좋아요'), findsOneWidget);
      expect(find.byTooltip('셔플'), findsOneWidget);
      expect(find.byTooltip('반복'), findsOneWidget);
      expect(find.byTooltip('가사 보기'), findsOneWidget);
      expect(find.byTooltip('재생 대기열'), findsOneWidget);
      expect(find.byTooltip('수면 타이머'), findsOneWidget);
      expect(find.byTooltip('이퀄라이저'), findsOneWidget);
      expect(find.byTooltip('10초 앞으로'), findsOneWidget);

      await tester.tap(find.byTooltip('좋아요'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('좋아요 취소'), findsOneWidget);

      await tester.tap(find.byTooltip('가사 보기'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('커버 보기'), findsOneWidget);
    });
  }

  testWidgets('10초 이동 버튼이 동작한다', (tester) async {
    await _openPlayer(tester, PlayerStyle.square);
    await tester.tap(find.byTooltip('10초 앞으로'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0:10'), findsOneWidget);
  });

  testWidgets('재생 화면 더 보기에서 플레이어 테마를 고르면 바로 바뀐다', (tester) async {
    await _openPlayer(tester, PlayerStyle.square);

    await tester.tap(find.byTooltip('곡 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('플레이어 테마'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('커스텀'));
    await tester.pumpAndSettle();
    expect(
      tester
          .element(find.byType(Scaffold).first)
          .read<PlayerStyleCubit>()
          .state,
      PlayerStyle.custom,
    );
  });

  testWidgets('커스텀 모양: 수면 타이머를 정하면 켜지고 끌 수 있다', (tester) async {
    await _openPlayer(tester, PlayerStyle.custom);

    await tester.tap(find.byTooltip('수면 타이머'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30분 뒤 멈춤'));
    await tester.pumpAndSettle();
    expect(find.text('30분 뒤 재생을 멈춰요'), findsOneWidget);
    // 하단 스낵바가 버튼을 가리지 않게 걷는다.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('수면 타이머'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('타이머 끄기'));
    await tester.pumpAndSettle();
    expect(find.text('수면 타이머를 껐어요'), findsOneWidget);
  });
}
