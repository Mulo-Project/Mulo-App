import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(
  String id,
  String title, {
  String artist = 'A가수',
  String genre = '락',
}) => Track(
  id: id,
  title: title,
  artist: artist,
  album: '앨범',
  genre: genre,
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

Future<void> _open(
  WidgetTester tester,
  String location, {
  required List<Track> tracks,
}) async {
  await setUpTestDependencies(tracks: tracks);
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.localesTestValue = const [Locale('ko')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(MusicApp(initialLocation: location));
  await tester.pumpAndSettle();
}

Future<void> _rename(WidgetTester tester, String tooltip, String to) async {
  // 이름 바꾸기는 정보 화면의 연필에서 한다.
  await tester.tap(find.byTooltip('정보'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(EditableText), to);
  await tester.tap(find.text('저장'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('아티스트 이름을 바꾸면 그 아티스트의 곡이 모두 새 이름으로 묶인다', (tester) async {
    await _open(
      tester,
      Routes.artist('A가수'),
      tracks: [
        _t('t1', '가 곡'),
        _t('t2', '나 곡'),
        _t('t3', '다 곡', artist: 'B가수'),
      ],
    );
    await _rename(tester, '아티스트 이름 바꾸기', 'C가수');
    // 바뀐 이름의 화면으로 가고, 곡 둘이 거기에 있다 (B가수의 곡은 그대로).
    expect(find.text('C가수'), findsWidgets);
    expect(find.text('가 곡'), findsOneWidget);
    expect(find.text('나 곡'), findsOneWidget);
    expect(find.text('다 곡'), findsNothing);
  });

  testWidgets('장르 이름을 바꾸면 그 장르의 곡이 새 장르가 된다 (곡이 많으면 진행 대화상자를 거친다)', (
    tester,
  ) async {
    await _open(
      tester,
      Routes.genre('락'),
      tracks: [
        for (var i = 1; i <= 5; i++) _t('t$i', '곡$i'),
        _t('t6', '다른 곡', genre: '팝'),
      ],
    );
    await _rename(tester, '장르 이름 바꾸기', '메탈');
    expect(find.text('메탈'), findsWidgets);
    expect(find.text('곡1'), findsOneWidget);
    expect(find.text('곡5'), findsOneWidget);
    expect(find.text('다른 곡'), findsNothing);
    // 진행 대화상자는 끝나면 닫힌다.
    expect(find.text('곡 정보를 고치는 중이에요'), findsNothing);
  });
}
