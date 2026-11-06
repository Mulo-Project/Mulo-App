import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/presentation/screens/library_screen.dart';
import 'package:music_download_play_app/features/library/presentation/widgets/track_menu.dart';
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
  late FakeTrackFiles files;

  Future<void> pumpLibrary(
    WidgetTester tester, {
    List<Playlist> lists = const [Playlist(id: 'pl1', name: '출근길')],
    bool deleteSucceeds = true,
  }) async {
    playlists = MemoryPlaylistRepository(lists);
    files = FakeTrackFiles(succeeds: deleteSucceeds);
    await setUpTestDependencies(
      tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡')],
      playlists: playlists,
      trackFiles: files,
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
    await tester.pumpAndSettle();
  }

  const items = ['다음에 재생', '대기열에 추가', '재생목록에 추가', '좋아요', '상세 정보', '삭제'];

  testWidgets('⋮ 버튼이 팝업 메뉴를 연다 (보관함 줄은 길게 누르면 선택 모드)', (tester) async {
    await pumpLibrary(tester);

    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    // 바닥 시트가 아니라 팝업 메뉴다.
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(PopupMenuItem<Object?>), findsNothing);
    for (final label in items) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // 보관함의 삭제는 하나 (재생목록 전용 항목은 없다).
    expect(find.text('재생목록에서 빼기'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('상세 정보'), findsNothing);
  });

  testWidgets('재생목록에 추가: 재생목록 화면으로 가서 카드를 골라 완료한다', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('재생목록에 추가'));
    await tester.pumpAndSettle();

    // 팝업이 아니라 화면이다. 좋아요 목록도 같이 보인다.
    expect(find.text('재생목록 선택'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('좋아요'), findsOneWidget);

    await tester.tap(find.text('출근길'));
    await tester.pump();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    expect(playlists.members['pl1'], {'t2'});
    expect(find.text('재생목록 선택'), findsNothing);
    expect(find.text('1개 재생목록에 담았어요'), findsOneWidget);
  });

  testWidgets('이미 담긴 재생목록은 "이미 담겼어요"로 보이고 새로 담지 않는다', (tester) async {
    await pumpLibrary(tester);
    await playlists.addTrack('t2', ['pl1']);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('재생목록에 추가'));
    await tester.pumpAndSettle();
    expect(find.text('이미 담겼어요'), findsOneWidget);
  });

  testWidgets('좋아요: 메뉴에서 켜고 끈다', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('좋아요'));
    await tester.pumpAndSettle();
    expect(playlists.members[Playlist.favoritesId], {'t2'});
    expect(find.text('좋아요에 담았어요'), findsNothing); // 하트가 바뀌므로 안내는 없다

    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('좋아요 취소'));
    await tester.pumpAndSettle();
    expect(playlists.members[Playlist.favoritesId], isEmpty);
  });

  testWidgets('상세 정보: 같은 화면에서 고치고 저장하면 목록에 반영되며, 제목이 비면 저장되지 않는다', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('상세 정보'));
    await tester.pumpAndSettle();
    // 먼저 정보를 보여 주고, 연필을 누르면 고치는 모드가 된다.
    expect(find.text('곡 상세 정보'), findsOneWidget);
    expect(find.text('길이'), findsOneWidget);
    await tester.tap(find.byTooltip('곡 정보 편집'));
    await tester.pumpAndSettle();

    final title = find.byType(EditableText).first;
    await tester.enterText(title, '');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('저장'), findsOneWidget);

    await tester.enterText(title, '고친 제목');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('저장'), findsNothing);
    expect(find.text('고친 제목'), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.text('고친 제목'), findsOneWidget);
    expect(find.text('둘째 곡'), findsOneWidget);
    expect(find.text('첫 곡'), findsNothing);
  });

  testWidgets('삭제: 확인하면 음악 파일과 보관함 기록이 지워지고, 취소하면 그대로', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.textContaining('음악 파일'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('둘째 곡'), findsOneWidget);
    expect(files.deleted, isEmpty);

    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    expect(find.text('둘째 곡'), findsNothing);
    expect(find.text('첫 곡'), findsOneWidget);
    expect(files.deleted, ['t2']);
  });

  testWidgets('파일을 못 지우면 보관함 기록은 그대로 두고 안내한다', (tester) async {
    await pumpLibrary(tester, deleteSucceeds: false);
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    expect(find.text('둘째 곡'), findsOneWidget);
    expect(find.textContaining('파일을 지우지 못했어요'), findsOneWidget);
  });

  testWidgets('재생목록 안의 곡: 삭제가 "빼기"와 "파일 삭제"로 나뉜다', (tester) async {
    await pumpLibrary(tester);
    await playlists.addTrack('t2', ['pl1']);
    final context = tester.element(find.byType(LibraryScreen));
    unawaited(showTrackMenu(context, _t('t2', '둘째 곡'), playlistId: 'pl1'));
    await tester.pumpAndSettle();
    expect(find.text('삭제'), findsNothing);
    expect(find.text('재생목록에서 빼기'), findsOneWidget);
    expect(find.text('파일 삭제'), findsOneWidget);

    // 빼기: 재생목록에서만 빠지고 파일 · 보관함은 그대로.
    await tester.tap(find.text('재생목록에서 빼기'));
    await tester.pumpAndSettle();
    expect(playlists.members['pl1'], isEmpty);
    expect(files.deleted, isEmpty);
    expect(find.text('둘째 곡'), findsOneWidget);

    // 파일 삭제: 음악 파일과 보관함 기록까지 지운다.
    unawaited(showTrackMenu(context, _t('t2', '둘째 곡'), playlistId: 'pl1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('파일 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    expect(files.deleted, ['t2']);
    expect(find.text('둘째 곡'), findsNothing);
  });
}
