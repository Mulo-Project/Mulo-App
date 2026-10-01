import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String title, String album) => Track(
  id: id,
  title: title,
  artist: '가수',
  album: album,
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

void main() {
  Future<void> pump(WidgetTester tester, String location) async {
    await setUpTestDependencies(
      tracks: [
        _t('t1', '다 곡', 'A앨범'),
        _t('t2', '가 곡', 'A앨범'),
        _t('t3', '다른 곡', 'B앨범'),
      ],
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(MusicApp(initialLocation: location));
    await tester.pumpAndSettle();
  }

  testWidgets('보관함 앨범 탭에서 앨범을 누르면 앨범 화면으로 가서 그 앨범의 곡만 보인다', (tester) async {
    await pump(tester, Routes.library);
    await tester.tap(find.text('앨범'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A앨범'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('뒤로'), findsOneWidget);
    expect(find.text('가 곡'), findsOneWidget);
    expect(find.text('다 곡'), findsOneWidget);
    expect(find.text('다른 곡'), findsNothing);
    expect(find.text('재생'), findsOneWidget);

    await tester.tap(find.text('재생'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('다음 곡'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('B앨범'), findsOneWidget);
  });

  testWidgets('없는 앨범이면 안내 문구', (tester) async {
    await pump(tester, Routes.album('없는 앨범'));
    expect(find.text('앨범을 찾을 수 없어요'), findsOneWidget);
  });
}
