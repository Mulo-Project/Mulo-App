import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String title, String genre) => Track(
  id: id,
  title: title,
  artist: '가수',
  album: '앨범',
  genre: genre,
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

void main() {
  Future<void> pump(WidgetTester tester, String location) async {
    await setUpTestDependencies(
      tracks: [
        _t('t1', '다 곡', '록'),
        _t('t2', '가 곡', '록'),
        _t('t3', '다른 곡', '재즈'),
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

  testWidgets('장르 탭에서 장르를 누르면 장르 화면이 열리고 재생 · 셔플 버튼이 있다', (tester) async {
    await pump(tester, Routes.library);
    await tester.tap(find.text('장르'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('록'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('뒤로'), findsOneWidget);
    expect(find.text('가 곡'), findsOneWidget);
    expect(find.text('다른 곡'), findsNothing);
    expect(find.text('재생'), findsOneWidget);
    expect(find.text('셔플'), findsOneWidget);
  });

  testWidgets('없는 장르면 안내 문구', (tester) async {
    await pump(tester, Routes.genre('없는 장르'));
    expect(find.text('장르를 찾을 수 없어요'), findsOneWidget);
  });
}
