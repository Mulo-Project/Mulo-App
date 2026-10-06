import 'package:music_download_play_app/core/design/components/app_dialog.dart';
import 'package:music_download_play_app/core/design/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:music_download_play_app/core/design/components/color_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_download_play_app/features/downloads/domain/usecases/download_usecases.dart';
import 'package:music_download_play_app/features/downloads/presentation/bloc/download_queue_cubit.dart';

import '../../helpers/fakes.dart';
import '../../helpers/open_download_dialog.dart';

const _now = DownloadItem(
  id: 'a',
  title: 'Now Song',
  artist: 'Now Artist',
  status: DownloadStatus.downloading,
  progress: .5,
);
const _next = DownloadItem(
  id: 'b',
  title: 'Next Song',
  artist: 'Next Artist',
  status: DownloadStatus.queued,
);
const _done = DownloadItem(
  id: 'c',
  title: 'Done Song',
  artist: 'Done Artist',
  status: DownloadStatus.done,
  progress: 1,
);

void main() {
  test('cubit: 받는 곡과 대기 곡을 나눈다 (완료는 제외)', () async {
    final repo = MemoryDownloadQueue([_next, _now, _done]);
    final cubit = DownloadQueueCubit(
      WatchDownloadQueue(repo),
      EnqueueDownload(repo),
      PauseDownload(repo),
      ResumeDownload(repo),
      CancelDownload(repo),
    )..start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.current, _now);
    expect(cubit.state.waiting, [_next]);

    repo.set([_done]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.current, isNull);
    expect(cubit.state.waiting, isEmpty);
    await cubit.close();
  });

  test('EnqueueDownload: 제목이 비면 받지 않고, 문자열 공백을 지운다', () async {
    final repo = MemoryDownloadQueue();
    final enqueue = EnqueueDownload(repo);
    expect(await enqueue(const DownloadRequest(title: '  ')), isFalse);
    expect(repo.requests, isEmpty);

    expect(
      await enqueue(
        const DownloadRequest(
          title: ' Song ',
          artist: ' Me ',
          genre: ' Pop ',
          playlistIds: {'pl1'},
        ),
      ),
      isTrue,
    );
    expect(repo.requests.single.title, 'Song');
    expect(repo.requests.single.artist, 'Me');
    expect(repo.requests.single.genre, 'Pop');
    expect(repo.requests.single.playlistIds, {'pl1'});
  });

  Future<MemoryDownloadQueue> openWithPlaylists(
    WidgetTester tester,
    List<Playlist> lists,
  ) async {
    final queue = MemoryDownloadQueue();
    await setUpTestDependencies(
      downloads: queue,
      playlists: MemoryPlaylistRepository(lists),
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
    await tester.pumpAndSettle();
    return queue;
  }

  Finder inSheet(Finder f) =>
      find.descendant(of: find.byType(BottomSheet), matching: f);

  testWidgets('받기 팝업: 정보 · 장르 · 재생목록을 정해 받는다', (tester) async {
    final queue = await openWithPlaylists(tester, const [
      Playlist(id: 'pl1', name: '운동'),
    ]);
    await openDownloadDialog(tester);
    expect(find.text('받기 정보'), findsOneWidget);

    final fields = inSheet(find.byType(TextField));
    await tester.enterText(fields.at(0), '내 제목');
    await tester.enterText(fields.at(1), '내 가수');
    await tester.enterText(fields.at(2), '발라드');
    // 저장 위치는 기본 저장 위치로 채워져 있고, 이 곡만 고칠 수 있다.
    expect(find.text('/music/Mulo'), findsOneWidget);
    await tester.enterText(fields.at(3), '/music/Mulo/발라드');

    // 재생목록 선택 대화상자에서 기존 재생목록을 고르고, 새로 만든다 (만들면 자동 선택).
    await tester.tap(find.text('선택 안 함'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('운동'));
    await tester.pump();
    final dialog = find.byType(AppDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      '새 목록',
    );
    await tester.tap(
      find.descendant(of: dialog, matching: find.byIcon(AppIcons.add)),
    );
    await tester.pumpAndSettle();
    expect(find.text('새 목록'), findsWidgets);
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();
    expect(find.text('2개 선택'), findsOneWidget);

    await tester.tap(inSheet(find.text('받기')));
    await tester.pumpAndSettle();

    final r = queue.requests.single;
    expect(r.title, '내 제목');
    expect(r.artist, '내 가수');
    expect(r.genre, '발라드');
    expect(r.savePath, '/music/Mulo/발라드');
    expect(r.playlistIds, {'pl1', 'pl2'});
    expect(find.text('받기 정보'), findsNothing);
  });

  testWidgets('받기 팝업: 색을 골라 받고, 장르 기본 색으로 저장하면 다음에 채워진다', (tester) async {
    final colors = MemoryCoverColorRepository();
    final queue = MemoryDownloadQueue();
    await setUpTestDependencies(downloads: queue, coverColors: colors);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
    await tester.pumpAndSettle();

    await openDownloadDialog(tester);
    final fields = inSheet(find.byType(TextField));
    await tester.enterText(fields.at(2), '발라드');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.bySemanticsLabel('색 3'));
    await tester.tap(find.bySemanticsLabel('색 3'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('기본 색으로 저장'));
    await tester.tap(find.textContaining('기본 색으로 저장'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('받기')));
    await tester.pumpAndSettle();

    final red = ColorPicker.presets[2].toARGB32();
    expect(queue.requests.single.color, red);
    expect(colors.saved['genre:발라드'], red);
  });

  testWidgets('받기 팝업: 제목을 비우면 받기 버튼이 눌리지 않는다', (tester) async {
    final queue = await openWithPlaylists(tester, const []);
    await openDownloadDialog(tester);
    expect(find.text('선택 안 함'), findsOneWidget);
    await tester.tap(find.text('선택 안 함'));
    await tester.pumpAndSettle();
    expect(find.text('아직 재생목록이 없어요. 아래에서 새로 만들 수 있어요.'), findsOneWidget);
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    await tester.enterText(inSheet(find.byType(TextField)).first, '');
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('받기')));
    await tester.pumpAndSettle();
    expect(queue.requests, isEmpty);
    expect(find.text('받기 정보'), findsOneWidget);
  });

  Future<void> open(WidgetTester tester, List<DownloadItem> queue) async {
    await setUpTestDependencies(downloads: MemoryDownloadQueue(queue));
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
    await tester.pumpAndSettle();
  }

  testWidgets('검색 탭: 받는 카드 → 화살표로 대기 목록 펼침', (tester) async {
    await open(tester, [_now, _next]);
    expect(find.text('Now Song'), findsOneWidget);
    expect(find.text('Next Song'), findsNothing);

    await tester.tap(find.byIcon(AppIcons.chevronDown));
    await tester.pumpAndSettle();
    expect(find.text('Next Song'), findsOneWidget);
  });

  testWidgets('대기열 카드: 일시정지 · 붙여넣기 버튼 없이 취소만', (tester) async {
    final queue = MemoryDownloadQueue([_now, _next]);
    await setUpTestDependencies(downloads: queue);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.pause), findsNothing);
    expect(find.byIcon(AppIcons.paste), findsNothing);
    await tester.tap(find.byIcon(AppIcons.close).first);
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.chevronDown));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.close).last);
    await tester.pump();
    expect(queue.controls, ['cancel:a', 'cancel:b']);
  });

  testWidgets('검색 탭: 받는 곡이 없으면 카드가 없다', (tester) async {
    await open(tester, [_done]);
    expect(find.text('Done Song'), findsNothing);
    expect(find.byIcon(AppIcons.chevronDown), findsNothing);
  });

  testWidgets('검색 대상 메뉴: 유튜브 → 웹', (tester) async {
    await open(tester, const []);
    // 검색창에는 아이콘만, 눌러서 연 메뉴에는 아이콘 + 이름.
    expect(find.text('유튜브'), findsNothing);
    expect(find.byKey(const ValueKey('youtube-mark')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('youtube-mark')));
    await tester.pumpAndSettle();
    expect(find.text('유튜브'), findsOneWidget);
    await tester.tap(find.text('웹'));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.globe), findsOneWidget);
    expect(find.text('웹'), findsNothing);
    expect(find.text('웹 음원 검색어나 URL'), findsOneWidget);
  });
}
