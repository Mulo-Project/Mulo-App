import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics_settings.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_settings_repository.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';
import 'package:music_download_play_app/features/player/presentation/screens/player_screen.dart';

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
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  /// 플레이어에서 첫 곡을 틀고 가사 보기로 바꾼 뒤 가사 편집 페이지를 연다.
  Future<void> openLyricsEditor(WidgetTester tester) async {
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    tester.element(find.byType(PlayerScreen)).read<NowPlayingCubit>().playQueue(
      [_t('t1', '첫 곡')],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('가사 편집'));
    await tester.pumpAndSettle();
  }

  testWidgets('가사 편집 페이지: 파일에서 불러와 저장하고, 비워 저장하면 지운다', (tester) async {
    phone(tester);
    final lyrics = MemoryLyricsRepository();
    final file = FakeLyricsFileSource('[00:01.00]불러온 가사');
    await setUpTestDependencies(lyrics: lyrics, lyricsFile: file);
    await openLyricsEditor(tester);

    await tester.tap(find.textContaining('파일에서 불러오기'));
    await tester.pumpAndSettle();
    expect(file.calls, 1);
    // 싱크 가사는 시간이 글과 따로 줄 옆에 보이고, 글에는 [] 표시가 섞이지 않는다.
    expect(find.text('00:01.00'), findsOneWidget);
    expect(find.text('불러온 가사'), findsOneWidget);
    expect(find.text('[00:01.00]불러온 가사'), findsNothing);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved['t1'], '[00:01.00]불러온 가사');
    expect(find.text('가사를 저장했어요'), findsNothing); // 화면이 닫히므로 안내는 없다

    // 글만 고치면 시간은 줄 번호에 맞춰 그대로 다시 붙는다.
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('가사 편집'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '불러온 가사'), '고친 가사');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved['t1'], '[00:01.00]고친 가사');

    // 다시 열면 저장된 글이 채워지고, 비워 저장하면 지운다.
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('가사 편집'));
    await tester.pumpAndSettle();
    expect(find.text('고친 가사'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '고친 가사'), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved, isEmpty);
    expect(find.text('가사를 지웠어요'), findsNothing);
  });

  testWidgets('플레이어: 중간 저장한 싱크 가사도 안 찍은 뒷부분까지 모두 보여 준다', (tester) async {
    phone(tester);
    final lyrics = MemoryLyricsRepository(
      sibling: {'t1': '[00:02.00]첫 줄\n둘째 줄\n셋째 줄'},
    );
    await setUpTestDependencies(lyrics: lyrics);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    tester.element(find.byType(PlayerScreen)).read<NowPlayingCubit>().playQueue(
      [_t('t1', '첫 곡')],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();
    expect(find.text('첫 줄'), findsOneWidget);
    expect(find.text('둘째 줄'), findsOneWidget);
    expect(find.text('셋째 줄'), findsOneWidget);
  });

  testWidgets('플레이어: 포커스 버튼을 끄면 재생해도 가사가 따라 올라가지 않는다', (tester) async {
    phone(tester);
    final raw = [
      for (var i = 0; i < 40; i++)
        '[00:${(i * 2).toString().padLeft(2, '0')}.00]줄 ${i + 1}',
    ].join('\n');
    final lyrics = MemoryLyricsRepository(sibling: {'t1': raw});
    await setUpTestDependencies(lyrics: lyrics);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    final player = tester
        .element(find.byType(PlayerScreen))
        .read<NowPlayingCubit>();
    player.playQueue([_t('t1', '첫 곡')]);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();

    double offset() => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    const hint = '켜면 목록이 포커스한 칸을 따라 움직이고, 끄면 가사를 자유롭게 볼 수 있어요';

    await tester.tap(find.byTooltip(hint));
    await tester.pumpAndSettle();
    final before = offset();
    player.seekTo(const Duration(seconds: 60));
    await tester.pumpAndSettle();
    expect(offset(), before);

    await tester.tap(find.byTooltip(hint));
    await tester.pumpAndSettle();
    player.seekTo(const Duration(seconds: 62));
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(before));
  });

  testWidgets('가사 편집 페이지: 시간이 같은 줄은 묶음으로 이어서 보인다', (tester) async {
    phone(tester);
    final lyrics = MemoryLyricsRepository(
      sibling: {'t1': '[00:01.00]가\n[00:01.00]나\n[00:03.00]다'},
    );
    await setUpTestDependencies(lyrics: lyrics);
    await openLyricsEditor(tester);

    // 묶음은 첫 줄에만 시간이 있고 다음 줄은 이어지는 선으로 보인다.
    expect(find.text('00:01.00'), findsOneWidget);
    expect(find.text('│'), findsOneWidget);
    expect(find.text('00:03.00'), findsOneWidget);
  });

  testWidgets('가사 편집 페이지: 시간 칸을 누르면 싱크를 묶거나 조절하거나 지울 수 있다', (tester) async {
    phone(tester);
    final lyrics = MemoryLyricsRepository(
      sibling: {'t1': '[00:01.00]가\n[00:02.00]나\n[00:03.00]다'},
    );
    await setUpTestDependencies(lyrics: lyrics);
    await openLyricsEditor(tester);

    // 첫째 줄의 시간 칸을 꾹 눌러 둘째 줄까지 끌어 묶는다.
    final from = tester.getCenter(find.text('00:01.00'));
    final to = tester.getCenter(find.text('00:02.00'));
    final drag = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 700));
    await drag.moveTo(to);
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('│'), findsOneWidget);

    // 셋째 줄부터 싱크를 지운다.
    await tester.tap(find.text('00:03.00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('여기부터 싱크 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('00:03.00'), findsNothing);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved['t1'], '[00:01.00]가\n[00:01.00]나\n다');
  });

  testWidgets('가사 편집 페이지: 가사가 있을 때 가져오면 바꿀지 붙일지 묻는다', (tester) async {
    phone(tester);
    final lyrics = MemoryLyricsRepository(sibling: {'t1': '기존 가사'});
    final file = FakeLyricsFileSource('[00:01.00]불러온 가사');
    await setUpTestDependencies(lyrics: lyrics, lyricsFile: file);
    await openLyricsEditor(tester);

    await tester.tap(find.textContaining('파일에서 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('가사가 이미 있어요'), findsOneWidget);
    await tester.tap(find.text('뒤에 붙이기'));
    await tester.pumpAndSettle();
    expect(find.text('기존 가사\n불러온 가사'), findsOneWidget);

    await tester.tap(find.textContaining('파일에서 불러오기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('바꾸기'));
    await tester.pumpAndSettle();
    expect(find.text('불러온 가사'), findsOneWidget);

    await tester.tap(find.textContaining('파일에서 불러오기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    expect(find.text('불러온 가사'), findsOneWidget);
  });

  testWidgets('가사 편집 페이지: 불러온 가사를 메모로 띄우고 줄을 눌러 지금 줄 아래에 끼워 넣는다', (
    tester,
  ) async {
    phone(tester);
    final lyrics = MemoryLyricsRepository(sibling: {'t1': '첫째 줄\n셋째 줄'});
    final file = FakeLyricsFileSource('[00:01.00]끼울 줄\n[00:02.00]다른 줄');
    await setUpTestDependencies(lyrics: lyrics, lyricsFile: file);
    await openLyricsEditor(tester);

    await tester.tap(find.textContaining('파일에서 불러오기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('메모로 띄우기'));
    await tester.pumpAndSettle();
    expect(find.text('불러온 가사'), findsOneWidget);
    expect(find.text('끼울 줄'), findsOneWidget);

    // 커서를 첫째 줄에 두고 메모의 줄을 누르면 첫째 줄 바로 아래에 들어간다.
    final field = tester.widget<TextField>(find.byType(TextField));
    field.controller!.selection = const TextSelection.collapsed(offset: 2);
    await tester.tap(find.text('끼울 줄'));
    await tester.pumpAndSettle();
    expect(field.controller!.text, '첫째 줄\n끼울 줄\n셋째 줄');
  });

  testWidgets('플레이어: 가사 보기로 바꾸면 줄이 보이고, 줄을 누르면 그 위치로 간다', (tester) async {
    phone(tester);
    await setUpTestDependencies(
      lyrics: MemoryLyricsRepository(
        sibling: {'t1': '[00:00.00]첫 줄\n[00:30.00]둘째 줄\n[01:00.00]셋째 줄'},
      ),
    );
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    final player = tester
        .element(find.byType(PlayerScreen))
        .read<NowPlayingCubit>();
    player.playQueue([_t('t1', '첫 곡')]);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();
    expect(find.text('둘째 줄'), findsOneWidget);

    await tester.tap(find.text('셋째 줄'));
    await tester.pumpAndSettle();
    expect(player.state.position, const Duration(minutes: 1));

    expect(find.byTooltip('가사 편집'), findsNothing);
    expect(find.text('싱크 설정'), findsOneWidget);
    await tester.tap(find.byTooltip('커버 보기'));
    await tester.pumpAndSettle();
    expect(find.text('둘째 줄'), findsNothing);
  });

  testWidgets('플레이어: 같은 시간으로 묶인 줄은 함께 강조되고 간격이 좁다', (tester) async {
    phone(tester);
    await setUpTestDependencies(
      lyrics: MemoryLyricsRepository(
        sibling: {'t1': '[00:00.00]가 줄\n[00:00.00]나 줄\n[00:30.00]다 줄'},
      ),
    );
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    final player = tester
        .element(find.byType(PlayerScreen))
        .read<NowPlayingCubit>();
    player.playQueue([_t('t1', '첫 곡')]);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();

    // 묶인 두 줄은 둘 다 현재 줄 글자 크기이고, 묶이지 않은 줄은 더 작다.
    double size(String t) =>
        tester.widget<Text>(find.text(t)).style?.fontSize ??
        DefaultTextStyle.of(tester.element(find.text(t))).style.fontSize!;
    expect(size('가 줄'), size('나 줄'));
    expect(size('가 줄'), greaterThan(size('다 줄')));
    // 묶인 줄 사이는 묶이지 않은 줄 사이보다 좁다.
    final gapIn =
        tester.getTopLeft(find.text('나 줄')).dy -
        tester.getTopLeft(find.text('가 줄')).dy;
    final gapOut =
        tester.getTopLeft(find.text('다 줄')).dy -
        tester.getTopLeft(find.text('나 줄')).dy;
    expect(gapIn, lessThan(gapOut));
  });

  testWidgets('가운데 한 줄 테마: 묶인 줄은 간격이 좁고 함께 가운데에 놓인다', (tester) async {
    phone(tester);
    await setUpTestDependencies(
      lyrics: MemoryLyricsRepository(
        sibling: {'t1': '[00:00.00]가 줄\n[00:00.00]나 줄\n[00:30.00]다 줄'},
      ),
    );
    (sl<LyricsSettingsRepository>() as MemoryLyricsSettingsRepository)
        .settings = const LyricsSettings(
      latencyMs: 0,
      theme: LyricsTheme.centered,
    );
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    final player = tester
        .element(find.byType(PlayerScreen))
        .read<NowPlayingCubit>();
    player.playQueue([_t('t1', '첫 곡')]);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();

    final a = tester.getCenter(find.text('가 줄')).dy;
    final b = tester.getCenter(find.text('나 줄')).dy;
    final c = tester.getCenter(find.text('다 줄')).dy;
    // 묶인 두 줄 사이가 묶이지 않은 줄까지보다 좁다.
    expect(b - a, lessThan(c - b));
  });

  testWidgets('플레이어: 가사가 없으면 안내와 가사 편집 버튼', (tester) async {
    phone(tester);
    await setUpTestDependencies();
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    tester.element(find.byType(PlayerScreen)).read<NowPlayingCubit>().playQueue(
      [_t('t1', '첫 곡')],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('가사 보기'));
    await tester.pumpAndSettle();
    expect(find.text('가사가 없어요'), findsOneWidget);
    // 가사가 없으면 싱크 설정 버튼은 보이지 않는다.
    expect(find.text('싱크 설정'), findsNothing);
    await tester.tap(find.text('가사 편집'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('싱크 맞추기'), findsNothing);
  });
}
