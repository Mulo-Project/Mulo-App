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

  testWidgets('곡 메뉴 › 가사 설정: 파일에서 불러와 저장하고, 비워 저장하면 지운다', (tester) async {
    phone(tester);
    final lyrics = MemoryLyricsRepository();
    final file = FakeLyricsFileSource('[00:01.00]불러온 가사');
    await setUpTestDependencies(
      tracks: [_t('t1', '첫 곡')],
      lyrics: lyrics,
      lyricsFile: file,
    );
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('가사 설정'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('파일에서 불러오기'));
    await tester.pumpAndSettle();
    expect(file.calls, 1);
    expect(find.text('[00:01.00]불러온 가사'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved['t1'], '[00:01.00]불러온 가사');
    expect(find.text('가사를 저장했어요'), findsOneWidget);

    // 다시 열면 저장된 글이 채워지고, 비워 저장하면 지운다.
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('가사 설정'));
    await tester.pumpAndSettle();
    expect(find.text('[00:01.00]불러온 가사'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(EditableText),
      ),
      '',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(lyrics.saved, isEmpty);
    expect(find.text('가사를 지웠어요'), findsOneWidget);
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

    await tester.tap(find.byTooltip('커버 보기'));
    await tester.pumpAndSettle();
    expect(find.text('둘째 줄'), findsNothing);
  });

  testWidgets('플레이어: 가사가 없으면 안내와 가사 설정 버튼', (tester) async {
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
    await tester.tap(find.text('가사 설정'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
  });
}
