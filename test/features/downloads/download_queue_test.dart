import 'package:music_download_play_app/features/search/presentation/screens/media_detail_screen.dart';
import 'package:music_download_play_app/core/design/components/app_dialog.dart';
import 'package:music_download_play_app/core/design/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:music_download_play_app/core/design/components/color_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/presentation/widgets/download_dialog.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_download_play_app/features/downloads/domain/usecases/download_usecases.dart';
import 'package:music_download_play_app/features/downloads/presentation/bloc/download_queue_cubit.dart';

import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/subtitle_track.dart';
import 'package:music_download_play_app/features/search/presentation/screens/search_screen.dart';

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
  test('cubit: 받는 곡을 고르고 남은 곡 수 · 전체 진행도를 센다', () async {
    final repo = MemoryDownloadQueue([_next, _now, _done]);
    final cubit = DownloadQueueCubit(
      WatchDownloadQueue(repo),
      EnqueueDownload(repo),
      PauseDownload(repo),
      ResumeDownload(repo),
      RetryDownload(repo),
      CancelDownload(repo),
      CancelAllDownloads(repo),
    )..start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.current, _now);
    expect(cubit.state.unfinishedCount, 2);
    expect(cubit.state.overallProgress, closeTo((.5 + 0 + 1) / 3, 1e-9));
    expect(cubit.state.unfinishedFor('none'), isEmpty);

    repo.set([_done]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.current, isNull);
    expect(cubit.state.unfinishedCount, 0);
    expect(cubit.state.overallProgress, 1);
    await cubit.close();
  });

  test('cubit: 전체 취소는 끝나지 않은 곡만 뺀다 (재생목록을 주면 그 곡만)', () async {
    const inList = DownloadItem(
      id: 'p',
      title: 'In List',
      artist: '',
      status: DownloadStatus.queued,
      playlistIds: {'pl'},
    );
    final repo = MemoryDownloadQueue([_now, inList, _done]);
    final cubit = DownloadQueueCubit(
      WatchDownloadQueue(repo),
      EnqueueDownload(repo),
      PauseDownload(repo),
      ResumeDownload(repo),
      RetryDownload(repo),
      CancelDownload(repo),
      CancelAllDownloads(repo),
    )..start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.unfinishedFor('pl'), [inList]);

    expect(await cubit.cancelAll(playlistId: 'pl'), 1);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.items, [_now, _done]);

    expect(await cubit.cancelAll(), 1);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.items, [_done]);
    await cubit.close();
  });

  test('EnqueueDownload: 제목이 비면 받지 않고, 문자열 공백을 지운다', () async {
    final repo = MemoryDownloadQueue();
    final enqueue = EnqueueDownload(repo);
    expect(
      await enqueue(
        const DownloadRequest(title: '  ', url: 'https://youtu.be/a'),
      ),
      isFalse,
    );
    expect(repo.requests, isEmpty);

    expect(
      await enqueue(
        const DownloadRequest(
          title: ' Song ',
          url: ' https://youtu.be/a ',
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
      find.descendant(of: find.byType(DownloadScreen), matching: f);

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
    await tester.ensureVisible(find.text('선택 안 함'));
    await tester.pumpAndSettle();
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

    await tester.ensureVisible(inSheet(find.text('받기')));
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
    await tester.ensureVisible(inSheet(find.text('받기')));
    await tester.tap(inSheet(find.text('받기')));
    await tester.pumpAndSettle();

    final red = ColorPicker.presets[2].toARGB32();
    expect(queue.requests.single.color, red);
    expect(colors.saved['genre:발라드'], red);
  });

  testWidgets('받기 팝업: 유튜브 곡은 자막을 가사로 가져오기를 켜고 받을 수 있다', (tester) async {
    final queue = MemoryDownloadQueue();
    await setUpTestDependencies(downloads: queue);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
    await tester.pumpAndSettle();

    await openDownloadDialog(tester);
    final row = find.byKey(const ValueKey('download-import-lyrics'));
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: inSheet(find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.ensureVisible(inSheet(find.text('받기')));
    await tester.tap(inSheet(find.text('받기')));
    await tester.pumpAndSettle();

    expect(queue.requests.single.importLyrics, isTrue);
  });

  Future<MemoryDownloadQueue> openLyricsPage(
    WidgetTester tester,
    FakeDownloaderEngine engine,
  ) async {
    final queue = MemoryDownloadQueue();
    await setUpTestDependencies(downloads: queue, engine: engine);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
    await tester.pumpAndSettle();
    await openDownloadDialog(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('download-import-lyrics')),
      200,
      scrollable: inSheet(find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    return queue;
  }

  testWidgets('받기 페이지: 자막이 없으면 알리고 가져오기를 켤 수 없다', (tester) async {
    final queue = await openLyricsPage(
      tester,
      FakeDownloaderEngine(
        info: const VideoInfo(
          MediaHit(id: 'abc', title: 'Song', url: 'https://youtu.be/abc'),
        ),
      ),
    );
    expect(find.text('이 영상에는 자막이 없어요.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('download-import-lyrics')));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('받기')));
    await tester.pumpAndSettle();
    expect(queue.requests.single.importLyrics, isFalse);
  });

  testWidgets('받기 페이지: 자막 언어를 보여 주고 고른 언어로 가져온다', (tester) async {
    final queue = await openLyricsPage(
      tester,
      FakeDownloaderEngine(
        info: const VideoInfo(
          MediaHit(
            id: 'abc',
            title: 'Song',
            url: 'https://youtu.be/abc',
            subtitleLangs: ['ko', 'en'],
          ),
        ),
      ),
    );
    expect(find.text('자막 2개를 찾았어요.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('download-import-lyrics')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('영어'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('영어'));
    await tester.pumpAndSettle();
    // 줄을 누르면 전체 가사 페이지가 열리고, 거기서 "이 자막 사용"으로 고른다.
    expect(find.byKey(const ValueKey('subtitle-detail-use')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('subtitle-detail-use')));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('받기')));
    await tester.pumpAndSettle();
    expect(queue.requests.single.importLyrics, isTrue);
    expect(queue.requests.single.lyricsLanguage, 'en');
  });

  testWidgets('받기 페이지: 언어가 많으면 5개씩 가로로 늘어나고, 줄을 누르면 가사 상세에서 읽는다', (
    tester,
  ) async {
    final engine =
        FakeDownloaderEngine(
            info: const VideoInfo(
              MediaHit(
                id: 'abc',
                title: 'Song',
                url: 'https://youtu.be/abc',
                subtitleLangs: ['ko', 'en', 'ja', 'fr', 'de', 'es'],
              ),
            ),
          )
          ..subtitles = const SubtitleTrack(
            language: 'ko',
            cues: [
              SubtitleCue(Duration(seconds: 1), '첫 줄 가사'),
              SubtitleCue(Duration(seconds: 70), '둘째 줄 가사'),
            ],
          );
    await openLyricsPage(tester, engine);
    await tester.tap(find.byKey(const ValueKey('download-import-lyrics')));
    await tester.pumpAndSettle();

    // 자동 줄 + 언어 6개 = 7줄 → 5줄 칸 + 2줄 칸, 가로로 민다.
    expect(
      find.descendant(
        of: inSheet(find.byType(SingleChildScrollView)),
        matching: find.text('언어'),
      ),
      findsNWidgets(2),
    );

    // 언어 줄을 누르면 상세 페이지에서 가사를 읽어 보여 준다 (별도 미리보기 버튼은 없다).
    final ko = find.text('한국어');
    await tester.ensureVisible(ko);
    await tester.pumpAndSettle();
    await tester.tap(ko);
    await tester.pumpAndSettle();
    expect(find.text('00:01.00'), findsOneWidget);
    expect(find.textContaining('첫 줄 가사'), findsOneWidget);
    expect(engine.subtitleUrls, ['https://youtu.be/abc']);
  });

  testWidgets('받기 페이지: 상세에서 가사 글을 고치면 고친 글이 받기 요청에 실린다', (tester) async {
    final engine =
        FakeDownloaderEngine(
            info: const VideoInfo(
              MediaHit(
                id: 'abc',
                title: 'Song',
                url: 'https://youtu.be/abc',
                subtitleLangs: ['ko', 'en'],
              ),
            ),
          )
          ..subtitles = const SubtitleTrack(
            language: 'en',
            cues: [SubtitleCue(Duration(seconds: 1), 'helo world')],
          );
    final queue = await openLyricsPage(tester, engine);
    await tester.tap(find.byKey(const ValueKey('download-import-lyrics')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('영어'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('영어'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'helo world'),
      'hello world',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('subtitle-detail-use')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('수정함'));
    await tester.pumpAndSettle();
    expect(find.textContaining('수정함'), findsOneWidget);
    await tester.tap(inSheet(find.text('받기')));
    await tester.pumpAndSettle();
    expect(queue.requests.single.lyricsLanguage, 'en');
    expect(queue.requests.single.lyricsText, '[00:01.00]hello world');
  });

  testWidgets('받기 페이지: 자막 언어가 하나여도 표가 보이고, 줄을 누르면 가사 상세로 간다', (tester) async {
    await openLyricsPage(
      tester,
      FakeDownloaderEngine(
        info: const VideoInfo(
          MediaHit(
            id: 'abc',
            title: 'Song',
            url: 'https://youtu.be/abc',
            subtitleLangs: ['ko'],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('download-import-lyrics')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('한국어'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('subtitle-detail-use')), findsOneWidget);
  });

  testWidgets('받기 팝업: 제목을 비우면 받기 버튼이 눌리지 않는다', (tester) async {
    final queue = await openWithPlaylists(tester, const []);
    await openDownloadDialog(tester);
    await tester.enterText(inSheet(find.byType(TextField)).first, '');
    await tester.pumpAndSettle();
    expect(find.text('선택 안 함'), findsOneWidget);
    await tester.ensureVisible(find.text('선택 안 함'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택 안 함'));
    await tester.pumpAndSettle();
    expect(find.text('아직 재생목록이 없어요. 아래에서 새로 만들 수 있어요.'), findsOneWidget);
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(inSheet(find.text('받기')));
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

  testWidgets('받기 줄: 현재 곡과 남은 곡 수만 보이고, 누르면 목록이 펼쳐진다', (tester) async {
    await open(tester, [_now, _next]);
    expect(find.byKey(const ValueKey('download-bar')), findsOneWidget);
    expect(find.text('Now Song'), findsOneWidget);
    expect(find.text('Next Song'), findsNothing);
    expect(find.textContaining('2곡 남음'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('download-bar-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Next Song'), findsOneWidget);
    expect(find.text('Now Song'), findsOneWidget);

    // 목록의 곡을 누르면 그 곡의 상세 화면이 열린다.
    await tester.tap(find.text('Next Song'));
    await tester.pumpAndSettle();
    expect(find.byType(MediaDetailScreen), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('download-bar-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Next Song'), findsNothing);
  });

  testWidgets('받기 줄: 전체 일시정지', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('download-pause-all')));
    await tester.pumpAndSettle();
    expect(queue.controls, ['pause:b', 'pause:a']);
  });

  testWidgets('대기열 카드: 곡 취소 · 전체 취소', (tester) async {
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

    expect(find.byIcon(AppIcons.paste), findsOneWidget); // 시작 화면의 링크 붙여넣기 버튼 하나
    // 펼친 목록에서 곡 하나만 취소한다.
    await tester.tap(find.byKey(const ValueKey('download-bar-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('취소').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소하기'));
    await tester.pumpAndSettle();
    expect(queue.controls, ['cancel:a']);
  });

  testWidgets('받기 줄을 접어 고정된 플로팅 버튼으로 두고, 누르면 다시 켜진다', (tester) async {
    await open(tester, [_now, _next]);
    expect(find.byKey(const ValueKey('download-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('download-float')), findsNothing);

    // 손잡이를 누르면 접힌다.
    await tester.tap(find.byKey(const ValueKey('download-minimize')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('download-bar')), findsNothing);
    final float = find.byKey(const ValueKey('download-float'));
    expect(float, findsOneWidget);

    // 버튼을 누르면 받기 줄이 다시 켜진다.
    await tester.tap(float);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('download-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('download-float')), findsNothing);
  });

  testWidgets('받기 줄 · 플로팅 버튼이 목록을 가리지 않게 화면 아래 여백이 그만큼 늘고, 줄을 접고 펴도 한 번만 바뀐다', (
    tester,
  ) async {
    await open(tester, [_now, _next]);
    double bottom() =>
        MediaQuery.paddingOf(tester.element(find.byType(SearchScreen))).bottom;
    final bar = tester.getSize(find.byKey(const ValueKey('download-bar')));
    final withBar = bottom();

    // 접는 동안 여백은 바뀌어도 끝난 뒤에는 플로팅 버튼 높이만큼이다.
    await tester.tap(find.byKey(const ValueKey('download-minimize')));
    await tester.pumpAndSettle();
    final withFloat = bottom();
    expect(withFloat, lessThan(withBar));
    expect(withFloat, greaterThan(withBar - bar.height));

    // 펴면 줄 높이만큼으로 돌아온다 (펴지는 동안 프레임마다 바뀌지 않고 한 값을 유지).
    await tester.tap(find.byKey(const ValueKey('download-float')));
    final seen = <double>{};
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      seen.add(bottom());
    }
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(bottom(), withBar);
    expect(seen.length, lessThanOrEqualTo(3));
  });

  testWidgets('받기 줄 손잡이를 아래로 끌면 접히고, 조금만 끌면 제자리로 돌아간다', (tester) async {
    await open(tester, [_now, _next]);
    final handle = find.byKey(const ValueKey('download-minimize'));

    await tester.drag(handle, const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('download-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('download-float')), findsNothing);

    await tester.drag(handle, const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('download-bar')), findsNothing);
    expect(find.byKey(const ValueKey('download-float')), findsOneWidget);
  });

  testWidgets('받기 취소 확인 창의 버튼은 한 줄에 나란히 놓인다', (tester) async {
    await open(tester, [_now, _next]);
    await tester.tap(find.byTooltip('전체 취소'));
    await tester.pumpAndSettle();
    final keep = tester.getCenter(find.text('계속 받기'));
    final cancel = tester.getCenter(
      find.descendant(of: find.byType(AppDialog), matching: find.text('전체 취소')),
    );
    expect(keep.dy, closeTo(cancel.dy, 1));
    expect(keep.dx, lessThan(cancel.dx));

    await tester.tap(find.text('계속 받기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('취소').first);
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('계속 받기')).dy,
      closeTo(tester.getCenter(find.text('취소하기')).dy, 1),
    );
  });

  testWidgets('검색 탭: 전체 취소는 확인한 뒤 모두 뺀다', (tester) async {
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

    await tester.tap(find.byTooltip('전체 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('계속 받기'));
    await tester.pumpAndSettle();
    expect(queue.controls, isEmpty);

    await tester.tap(find.byTooltip('전체 취소'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AppDialog), matching: find.text('전체 취소')),
    );
    await tester.pumpAndSettle();
    expect(queue.controls, ['cancelAll:']);
    expect(find.text('Now Song'), findsNothing);
  });

  testWidgets('재생목록 상세: 이 재생목록에 담을 곡마다 진행도, 전체 취소는 그 곡만', (tester) async {
    const mine = DownloadItem(
      id: 'm',
      title: 'Mine Song',
      artist: 'A',
      status: DownloadStatus.downloading,
      progress: .25,
      playlistIds: {'pl'},
    );
    const other = DownloadItem(
      id: 'o',
      title: 'Other Song',
      artist: 'B',
      status: DownloadStatus.queued,
      playlistIds: {'other'},
    );
    final queue = MemoryDownloadQueue([mine, other]);
    await setUpTestDependencies(
      downloads: queue,
      playlists: MemoryPlaylistRepository([
        const Playlist(id: 'pl', name: '가져온 목록', trackCount: 0),
      ]),
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(
      MusicApp(initialLocation: Routes.playlistDetail('pl')),
    );
    await tester.pumpAndSettle();

    expect(find.text('받는 중 1곡'), findsOneWidget);
    // 하단 받기 줄의 현재 곡.
    expect(find.text('Mine Song'), findsNWidgets(2));
    expect(find.text('받는 중 25%'), findsNWidgets(2)); // 재생목록 영역 + 받기 줄
    expect(find.text('Other Song'), findsNothing);

    await tester.tap(find.byTooltip('전체 취소').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AppDialog), matching: find.text('전체 취소')),
    );
    await tester.pumpAndSettle();
    expect(queue.controls, ['cancelAll:pl']);
    expect(find.text('Mine Song'), findsNothing);
  });

  testWidgets('검색 탭: 받는 곡이 없으면 카드가 없다', (tester) async {
    await open(tester, [_done]);
    expect(find.text('Done Song'), findsNothing);
    expect(find.byIcon(AppIcons.chevronDown), findsNothing);
  });

  testWidgets('검색 대상 메뉴: 유튜브 → SoundCloud, 오른쪽 버튼으로 검색', (tester) async {
    await open(tester, const []);
    // 검색창에는 아이콘만, 눌러서 연 메뉴에는 아이콘 + 이름.
    expect(find.text('유튜브'), findsNothing);
    expect(find.byKey(const ValueKey('youtube-mark')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('youtube-mark')));
    await tester.pumpAndSettle();
    expect(find.text('유튜브'), findsOneWidget);
    await tester.tap(find.text('SoundCloud'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('youtube-mark')), findsNothing);
    expect(find.text('SoundCloud URL이나 검색어'), findsOneWidget);
    // 오른쪽 검색 버튼
    expect(find.byTooltip('검색'), findsOneWidget);
  });
}
