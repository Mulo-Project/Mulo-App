import 'package:music_download_play_app/core/design/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

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

void main() {
  testWidgets('플레이어의 대기열 버튼은 바닥 시트가 아니라 대기열 화면을 연다', (tester) async {
    await setUpTestDependencies(tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡')]);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
    await tester.pumpAndSettle();

    // 곡을 재생하고 전체 화면 플레이어로.
    await tester.tap(find.text('첫 곡'));
    await tester.pumpAndSettle();
    final router = tester.element(find.byType(Scaffold).first);
    GoRouter.of(router).push(Routes.player);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('재생 대기열'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('2곡'), findsOneWidget);
    expect(find.text('첫 곡'), findsOneWidget);
    expect(find.text('둘째 곡'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('재생 대기열'), findsOneWidget);
  });

  Future<void> openQueue(WidgetTester tester) async {
    await setUpTestDependencies(
      tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡'), _t('t3', '셋째 곡')],
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
  }

  testWidgets('미니 플레이어의 대기열 버튼이 대기열 화면을 바로 연다', (tester) async {
    await openQueue(tester);
    await tester.tap(find.byTooltip('재생 대기열'));
    await tester.pumpAndSettle();
    expect(find.text('3곡'), findsOneWidget);
    expect(find.text('길게 눌러 끌면 순서가 바뀌어요'), findsOneWidget);
  });

  testWidgets('대기열: 전체 섞기 · 비우기, 곡 메뉴', (tester) async {
    await openQueue(tester);
    await tester.tap(find.byTooltip('재생 대기열'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('전체 섞기'));
    await tester.pumpAndSettle();
    expect(find.text('3곡'), findsOneWidget);

    // 보관함과 같은 곡 메뉴.
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    expect(find.text('다음에 재생'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // 취소하면 그대로.
    await tester.tap(find.byTooltip('대기열 비우기'));
    await tester.pumpAndSettle();
    expect(find.text('대기열을 비울까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('3곡'), findsOneWidget);

    // 확인하면 재생 중인 곡까지 모두 비운다.
    await tester.tap(find.byTooltip('대기열 비우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('비우기'));
    await tester.pumpAndSettle();
    expect(find.text('대기열이 비어 있어요'), findsOneWidget);
    expect(find.text('첫 곡'), findsNothing);
  });

  testWidgets('대기열: 길게 눌러 끌면 순서가 바뀌고 재생 중인 곡은 그대로', (tester) async {
    await openQueue(tester);
    await tester.tap(find.byTooltip('재생 대기열'));
    await tester.pumpAndSettle();

    final first = tester.getCenter(find.text('첫 곡'));
    final third = tester.getCenter(find.text('셋째 곡'));
    final gesture = await tester.startGesture(first);
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(third + const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final order = [
      for (final t in ['첫 곡', '둘째 곡', '셋째 곡'])
        tester.getTopLeft(find.text(t)).dy,
    ];
    // 첫 곡이 맨 아래로 내려갔다.
    expect(order[0], greaterThan(order[1]));
    expect(order[0], greaterThan(order[2]));
  });

  testWidgets('전체 화면 플레이어에 좋아요 하트가 있고 누르면 켜진다', (tester) async {
    await openQueue(tester);
    final router = tester.element(find.byType(Scaffold).first);
    GoRouter.of(router).push(Routes.player);
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.favoriteOutline), findsOneWidget);
    await tester.tap(find.byTooltip('좋아요').last);
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.favorite), findsOneWidget);
    expect(find.byTooltip('좋아요 취소'), findsOneWidget);
  });
}
