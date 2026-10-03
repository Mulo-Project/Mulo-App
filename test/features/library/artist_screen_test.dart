import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String title, String artist) => Track(
  id: id,
  title: title,
  artist: artist,
  album: '앨범',
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

void main() {
  Future<void> pump(WidgetTester tester, String location) async {
    await setUpTestDependencies(
      tracks: [
        _t('t1', '다 곡', 'A가수'),
        _t('t2', '가 곡', 'A가수'),
        _t('t3', '다른 곡', 'B가수'),
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

  testWidgets('아티스트 탭에서 아티스트를 누르면 그 아티스트의 곡 목록이 보인다', (tester) async {
    await pump(tester, Routes.library);
    await tester.tap(find.text('아티스트'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A가수'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('뒤로'), findsOneWidget);
    expect(find.text('가 곡'), findsOneWidget);
    expect(find.text('다 곡'), findsOneWidget);
    expect(find.text('다른 곡'), findsNothing);
  });

  testWidgets('꾸미기 시트에서 이미지와 색을 한 곳에서 고른다', (tester) async {
    await pump(tester, Routes.artist('A가수'));
    await tester.tap(find.byTooltip('아티스트 꾸미기'));
    await tester.pumpAndSettle();

    expect(find.text('꾸미기'), findsOneWidget);
    expect(find.text('사진에서 고르기'), findsOneWidget);
    expect(find.text('색'), findsOneWidget);
  });

  testWidgets('없는 아티스트면 안내 문구', (tester) async {
    await pump(tester, Routes.artist('없는 가수'));
    expect(find.text('아티스트를 찾을 수 없어요'), findsOneWidget);
  });
}
