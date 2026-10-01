import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';

import '../../helpers/fakes.dart';

void main() {
  late MemoryPlaylistRepository repo;

  setUp(() {
    repo = MemoryPlaylistRepository(const [
      Playlist(
        id: 'pl1',
        name: '출근길',
        trackCount: 2,
        topTracks: [PlaylistTrackPreview(id: 't1', title: '첫 곡', artist: '가수')],
      ),
      Playlist(id: 'pl2', name: '운동', trackCount: 5, topArtists: ['아티스트A']),
    ]);
  });

  Future<void> pumpPlaylists(WidgetTester tester) async {
    await setUpTestDependencies(playlists: repo);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.playlists));
    await tester.pumpAndSettle();
  }

  testWidgets('카드 아래에 많이 들은 곡 또는 주요 아티스트가 보인다', (tester) async {
    await pumpPlaylists(tester);
    expect(find.text('출근길'), findsOneWidget);
    expect(find.text('첫 곡'), findsOneWidget);
    expect(find.text('아티스트A'), findsOneWidget);
  });

  testWidgets('카드를 길게 누르면 설정 메뉴가 열리고 카드 색을 고를 수 있다', (tester) async {
    await pumpPlaylists(tester);
    await tester.longPress(find.text('출근길'));
    await tester.pumpAndSettle();
    expect(find.text('이미지 바꾸기'), findsOneWidget);
    expect(find.text('카드 색'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('카드 색 보조 색'));
    await tester.pumpAndSettle();
    expect(repo.colors['pl1'], 1);

    await tester.tap(find.bySemanticsLabel('자동'));
    await tester.pumpAndSettle();
    expect(repo.colors['pl1'], isNull);
  });

  testWidgets('이미지 바꾸기 버튼 위를 길게 눌러도 설정 메뉴가 열린다', (tester) async {
    await pumpPlaylists(tester);
    await tester.longPress(find.byTooltip('커버 이미지 바꾸기').first);
    await tester.pumpAndSettle();
    expect(find.text('카드 색'), findsOneWidget);
  });

  testWidgets('+ 버튼으로 새 재생목록을 만든다', (tester) async {
    await pumpPlaylists(tester);
    await tester.tap(find.byTooltip('새 재생목록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '새 목록');
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    expect(find.text('새 목록'), findsOneWidget);
  });
}
