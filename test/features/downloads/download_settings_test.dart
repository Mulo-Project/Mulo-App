import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/presentation/widgets/download_dialog.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_options.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';
import '../../helpers/open_download_dialog.dart';

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

  testWidgets('설정의 저장 위치: 대화상자에서 "직접 선택"으로 폴더 선택기를 열면 기본 저장 위치가 된다', (
    tester,
  ) async {
    final settings = MemoryDownloadSettings(
      path: '/music/Mulo',
      picked: '/music/내폴더',
    );
    await pump(tester, Routes.settings, settings: settings, height: 7000);
    expect(find.text('/music/Mulo'), findsOneWidget);

    await tester.tap(find.text('저장 위치'));
    await tester.pumpAndSettle();
    // 바로 선택기가 뜨지 않고 목록 대화상자가 먼저 뜬다.
    expect(find.text('저장 위치 고르기'), findsOneWidget);
    expect(settings.path, '/music/Mulo');

    await tester.tap(find.text('직접 선택'));
    await tester.pumpAndSettle();
    expect(settings.path, '/music/내폴더');
    expect(find.text('/music/내폴더'), findsOneWidget);
  });

  testWidgets('저장 위치 시트: 선택기를 취소하거나 시트를 닫아도 그대로다', (tester) async {
    final settings = MemoryDownloadSettings(path: '/music/Mulo');
    await pump(tester, Routes.settings, settings: settings, height: 7000);
    await tester.tap(find.text('저장 위치'));
    await tester.pumpAndSettle();
    // 선택기를 취소하면 시트는 그대로 남는다.
    await tester.tap(find.text('직접 선택'));
    await tester.pumpAndSettle();
    expect(find.text('저장 위치 고르기'), findsOneWidget);
    expect(settings.path, '/music/Mulo');
    // 시트 밖을 눌러 닫는다.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('저장 위치 고르기'), findsNothing);
    expect(settings.path, '/music/Mulo');
  });

  testWidgets('받기 팝업: 기존 장르를 한 번 눌러 채운다', (tester) async {
    await pump(
      tester,
      Routes.search,
      tracks: [_t('1', '발라드'), _t('2', '발라드'), _t('3', '록'), _t('4', '')],
    );
    await openDownloadDialog(tester);

    final sheet = find.byType(DownloadScreen);
    Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
    expect(inSheet(find.text('기존 장르에서 고르기')), findsOneWidget);
    // 장르 없는 곡은 제안하지 않는다.
    expect(inSheet(find.text('발라드')), findsOneWidget);
    expect(inSheet(find.text('록')), findsOneWidget);

    await tester.tap(inSheet(find.text('록')));
    await tester.pump();
    expect(find.text('록'), findsNWidgets(2)); // 입력칸 + 제안 칩
  });

  testWidgets('설정의 저장 형식은 기기 정책이 허용한 것만 보여 준다', (tester) async {
    final settings = MemoryDownloadSettings()
      ..formats = const [AudioFormat.opus, AudioFormat.mp3];
    await pump(tester, Routes.settings, settings: settings, height: 7000);
    expect(find.text('opus'), findsOneWidget);
    expect(find.text('mp3'), findsOneWidget);
    expect(find.text('m4a'), findsNothing);
  });
}
