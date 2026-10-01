import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';

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
  late MemoryPlaylistRepository repo;
  late MemoryCoverRepository covers;

  setUp(() {
    final tracks = [_t('t1', '첫 곡'), _t('t2', '둘째 곡')];
    repo = MemoryPlaylistRepository(const [
      Playlist(
        id: 'pl1',
        name: '출근길',
        trackCount: 2,
        featured: PlaylistTrackPreview(id: 't1', title: '첫 곡', artist: '가수'),
      ),
      Playlist(id: 'pl2', name: '운동', trackCount: 5),
    ], tracks);
    repo.members['pl1'] = {'t1', 't2'};
    covers = MemoryCoverRepository();
  });

  Future<void> pumpPlaylists(
    WidgetTester tester, {
    FakeImageSource? image,
  }) async {
    await setUpTestDependencies(
      tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡')],
      playlists: repo,
      covers: covers,
      imageSource: image,
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.playlists));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, {int card = 1}) async {
    await tester.tap(find.byTooltip('재생목록 메뉴').at(card));
    await tester.pumpAndSettle();
  }

  testWidgets('카드는 대표곡 하나를 보여 주고, 좋아요 목록이 맨 앞에 있다', (tester) async {
    await pumpPlaylists(tester);
    expect(find.text('출근길'), findsOneWidget);
    expect(find.textContaining('첫 곡'), findsOneWidget);
    expect(find.textContaining('둘째 곡'), findsNothing);
    expect(find.text('좋아요'), findsOneWidget);
    // 좋아요가 첫 카드.
    expect(
      tester.getTopLeft(find.text('좋아요')).dx,
      lessThan(tester.getTopLeft(find.text('출근길')).dx),
    );
  });

  testWidgets('⋮ 를 누르면 팝업 메뉴가 열린다 (바닥 시트 아님)', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    expect(find.byType(BottomSheet), findsNothing);
    for (final label in ['전체 재생', '카드 색', '이미지 바꾸기', '이름 바꾸기', '재생목록 삭제']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('길게 누르면 같은 메뉴가 열린다', (tester) async {
    await pumpPlaylists(tester);
    await tester.longPress(find.text('출근길'));
    await tester.pumpAndSettle();
    expect(find.text('카드 색'), findsOneWidget);
    expect(find.text('재생목록 삭제'), findsOneWidget);
  });

  testWidgets('카드 색은 하위 메뉴에서 색 아이콘과 이름으로 고른다', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('카드 색'));
    await tester.pumpAndSettle();
    for (final label in ['자동', '주 색', '보조 색', '포인트 색']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.text('보조 색'));
    await tester.pumpAndSettle();
    expect(repo.colors['pl1'], 1);

    await openMenu(tester);
    await tester.tap(find.text('카드 색'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('자동'));
    await tester.pumpAndSettle();
    expect(repo.colors['pl1'], isNull);
  });

  testWidgets('이미지는 따로 열리는 팝업에서 고른다', (tester) async {
    await pumpPlaylists(tester, image: FakeImageSource('/tmp/pl.png'));
    await openMenu(tester);
    await tester.tap(find.text('이미지 바꾸기'));
    await tester.pumpAndSettle();
    expect(find.text('사진에서 고르기'), findsOneWidget);
    expect(find.text('기본 이미지로'), findsNothing);
    await tester.tap(find.text('사진에서 고르기'));
    await tester.pumpAndSettle();
    expect(covers.saved['playlist:pl1'], '/tmp/pl.png');

    // 이미지가 생기면 색 항목은 숨고, 기본 이미지로 되돌릴 수 있다.
    await openMenu(tester);
    expect(find.text('카드 색'), findsNothing);
    await tester.tap(find.text('이미지 바꾸기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기본 이미지로'));
    await tester.pumpAndSettle();
    expect(covers.saved, isEmpty);
  });

  testWidgets('좋아요 목록 메뉴에는 색 · 이름 · 삭제가 없다', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester, card: 0);
    expect(find.text('전체 재생'), findsOneWidget);
    expect(find.text('이미지 바꾸기'), findsOneWidget);
    expect(find.text('카드 색'), findsNothing);
    expect(find.text('이름 바꾸기'), findsNothing);
    expect(find.text('재생목록 삭제'), findsNothing);
  });

  testWidgets('이름 바꾸기', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('이름 바꾸기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '퇴근길');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('퇴근길'), findsOneWidget);
    expect(find.text('출근길'), findsNothing);
  });

  testWidgets('삭제: 확인하면 재생목록이 사라진다', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('재생목록 삭제'));
    await tester.pumpAndSettle();
    expect(find.textContaining('보관함에 그대로 남아요'), findsOneWidget);
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();
    expect(find.text('출근길'), findsNothing);
    expect(find.text('재생목록을 지웠어요'), findsOneWidget);
  });

  testWidgets('+ 버튼으로 이름 · 색을 골라 새 재생목록을 만든다', (tester) async {
    await pumpPlaylists(tester);
    await tester.tap(find.byTooltip('새 재생목록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '새 목록');
    await tester.tap(find.bySemanticsLabel('카드 색 포인트 색'));
    await tester.pump();
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    expect(find.text('새 목록'), findsOneWidget);
    expect(repo.lists.last.colorIndex, 2);
  });

  testWidgets('새 재생목록을 만들 때 이미지를 고르면 커버로 저장된다', (tester) async {
    await pumpPlaylists(tester, image: FakeImageSource('/tmp/new.png'));
    await tester.tap(find.byTooltip('새 재생목록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '새 목록');
    await tester.tap(find.text('이미지 고르기'));
    await tester.pumpAndSettle();
    // 이미지를 고르면 색 고르기는 사라진다.
    expect(find.text('이미지 바꾸기'), findsOneWidget);
    expect(find.bySemanticsLabel('카드 색 주 색'), findsNothing);
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    expect(covers.saved['playlist:pl3'], '/tmp/new.png');
    expect(repo.lists.last.colorIndex, isNull);
  });

  testWidgets('카드를 누르면 재생목록 상세로 가서 담긴 곡이 보이고, 곡 메뉴는 빼기 · 파일 삭제', (
    tester,
  ) async {
    await pumpPlaylists(tester);
    await tester.tap(find.text('출근길'));
    await tester.pumpAndSettle();
    // 상세: 탭 목록이 아니라 별도 페이지.
    expect(find.text('운동'), findsNothing);
    expect(find.text('첫 곡'), findsOneWidget);
    expect(find.text('둘째 곡'), findsOneWidget);
    expect(find.text('전체 재생'), findsOneWidget);

    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    expect(find.text('재생목록에서 빼기'), findsOneWidget);
    expect(find.text('파일 삭제'), findsOneWidget);
    await tester.tap(find.text('재생목록에서 빼기'));
    await tester.pumpAndSettle();
    expect(repo.members['pl1'], {'t2'});

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('운동'), findsOneWidget);
  });

  testWidgets('전체 재생: 담긴 곡으로 대기열이 채워져 미니 플레이어가 나온다', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('전체 재생'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('다음 곡'), findsOneWidget);
  });
}
