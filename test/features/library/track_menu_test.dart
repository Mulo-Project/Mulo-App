import 'package:flutter/gestures.dart';
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
  late MemoryPlaylistRepository playlists;

  Future<void> pumpLibrary(
    WidgetTester tester, {
    List<Playlist> lists = const [Playlist(id: 'pl1', name: '출근길')],
  }) async {
    playlists = MemoryPlaylistRepository(lists);
    await setUpTestDependencies(
      tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡')],
      playlists: playlists,
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
    await tester.pumpAndSettle();
  }

  const items = [
    '다음에 재생',
    '대기열에 추가',
    '재생목록에 추가',
    '정보 편집',
    '가사 설정',
    '커버 이미지 설정',
    '삭제',
  ];

  testWidgets('⋮ 버튼 · 길게 누르기 · 오른쪽 클릭이 같은 메뉴를 연다', (tester) async {
    await pumpLibrary(tester);

    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    for (final label in items) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('정보 편집'), findsNothing);

    await tester.longPress(find.text('첫 곡'));
    await tester.pumpAndSettle();
    expect(find.text('정보 편집'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('첫 곡'),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('정보 편집'), findsOneWidget);
  });

  testWidgets('재생목록에 추가: 다중 선택 대화상자에서 골라 담는다', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('재생목록에 추가'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('출근길'));
    await tester.pump();
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    expect(playlists.members['pl1'], {'t2'});
    expect(find.text('1개 재생목록에 담았어요'), findsOneWidget);
  });

  testWidgets('재생목록이 없으면 안내만 보여 준다', (tester) async {
    await pumpLibrary(tester, lists: const []);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('재생목록에 추가'));
    await tester.pumpAndSettle();
    expect(find.textContaining('재생목록이 없어요'), findsOneWidget);
    expect(find.text('선택 완료'), findsNothing);
  });

  testWidgets('정보 편집: 저장하면 목록에 바로 반영되고, 제목이 비면 저장되지 않는다', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('정보 편집'));
    await tester.pumpAndSettle();

    final title = find
        .descendant(
          of: find.byType(Dialog),
          matching: find.byType(EditableText),
        )
        .first;
    await tester.enterText(title, '');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('곡 정보 편집'), findsOneWidget);

    await tester.enterText(title, '고친 제목');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('곡 정보 편집'), findsNothing);
    expect(find.text('고친 제목'), findsOneWidget);
    expect(find.text('둘째 곡'), findsNothing);
    expect(find.text('첫 곡'), findsOneWidget);
  });

  testWidgets('삭제: 확인하면 보관함에서 빠지고, 취소하면 그대로', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('둘째 곡'), findsOneWidget);

    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    expect(find.text('둘째 곡'), findsNothing);
    expect(find.text('첫 곡'), findsOneWidget);
  });
}
