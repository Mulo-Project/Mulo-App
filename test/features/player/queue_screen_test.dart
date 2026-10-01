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
}
