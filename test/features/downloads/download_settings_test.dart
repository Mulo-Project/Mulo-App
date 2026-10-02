import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String genre) => Track(
  id: id,
  title: '곡$id',
  artist: '가수',
  album: '앨범',
  genre: genre,
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, 1),
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    String at, {
    List<Track> tracks = const [],
    MemoryDownloadSettings? settings,
    double height = 2532,
  }) async {
    await setUpTestDependencies(tracks: tracks, downloadSettings: settings);
    tester.view.physicalSize = Size(1170, height);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(MusicApp(initialLocation: at));
    await tester.pumpAndSettle();
  }

  testWidgets('설정의 저장 위치를 폴더 선택기로 바꾸면 기본 저장 위치가 된다', (tester) async {
    final settings = MemoryDownloadSettings(
      path: '/music/Mulo',
      picked: '/music/내폴더',
    );
    await pump(tester, Routes.settings, settings: settings, height: 7000);
    expect(find.text('/music/Mulo'), findsOneWidget);

    await tester.tap(find.text('저장 위치'));
    await tester.pumpAndSettle();
    expect(settings.path, '/music/내폴더');
    expect(find.text('/music/내폴더'), findsOneWidget);
  });

  testWidgets('선택기를 취소하면 저장 위치는 그대로다', (tester) async {
    final settings = MemoryDownloadSettings(path: '/music/Mulo');
    await pump(tester, Routes.settings, settings: settings, height: 7000);
    await tester.tap(find.text('저장 위치'));
    await tester.pumpAndSettle();
    expect(settings.path, '/music/Mulo');
  });

  testWidgets('받기 팝업: 기존 장르를 한 번 눌러 채운다', (tester) async {
    await pump(
      tester,
      Routes.search,
      tracks: [_t('1', '발라드'), _t('2', '발라드'), _t('3', '록'), _t('4', '')],
    );
    await tester.enterText(find.byType(TextField).first, 'https://youtu.be/x');
    await tester.pumpAndSettle();
    await tester.tap(find.text('받기').last);
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
    expect(inSheet(find.text('기존 장르에서 고르기')), findsOneWidget);
    // 장르 없는 곡은 제안하지 않는다.
    expect(inSheet(find.text('발라드')), findsOneWidget);
    expect(inSheet(find.text('록')), findsOneWidget);

    await tester.tap(inSheet(find.text('록')));
    await tester.pump();
    expect(find.text('록'), findsNWidgets(2)); // 입력칸 + 제안 칩
  });
}
