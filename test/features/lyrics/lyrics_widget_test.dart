import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
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
    expect(find.text('가사를 저장했어요'), findsOneWidget);

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
    await tester.tap(find.byTooltip('줄 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved, isEmpty);
    expect(find.text('가사를 지웠어요'), findsOneWidget);
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
    expect(find.text('기존 가사\n[00:01.00]불러온 가사'), findsOneWidget);

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
