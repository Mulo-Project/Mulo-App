import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String title, {String genre = '락'}) => Track(
  id: id,
  title: title,
  artist: '가수',
  album: '앨범',
  genre: genre,
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

final _dialogField = find.descendant(
  of: find.byType(AppDialog),
  matching: find.byType(EditableText),
);

void main() {
  Future<void> pumpLibrary(WidgetTester tester) async {
    await setUpTestDependencies(
      tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡'), _t('t3', '셋째 곡')],
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
    await tester.pumpAndSettle();
  }

  testWidgets('길게 누르면 선택 모드, 누르면 고르고 풀며 모두 풀면 끝난다', (tester) async {
    await pumpLibrary(tester);
    await tester.longPress(find.text('첫 곡'));
    await tester.pumpAndSettle();
    // 팝업 메뉴가 아니라 선택 모드다.
    expect(find.text('정보 편집'), findsNothing);
    expect(find.text('1곡 선택'), findsOneWidget);
    expect(find.byTooltip('곡 메뉴'), findsNothing);

    await tester.tap(find.text('둘째 곡'));
    await tester.pumpAndSettle();
    expect(find.text('2곡 선택'), findsOneWidget);

    await tester.tap(find.byTooltip('모두 선택'));
    await tester.pumpAndSettle();
    expect(find.text('3곡 선택'), findsOneWidget);

    await tester.tap(find.byTooltip('선택 끝내기'));
    await tester.pumpAndSettle();
    expect(find.text('3곡 선택'), findsNothing);
    expect(find.byTooltip('곡 메뉴'), findsWidgets);
  });

  testWidgets('고른 곡에 장르를 지정하면 확인창을 거쳐 그 곡들만 바뀐다', (tester) async {
    await pumpLibrary(tester);
    await tester.longPress(find.text('첫 곡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('둘째 곡'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    // 복수 작업 목록 바텀 시트.
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('장르 지정'));
    await tester.pumpAndSettle();
    await tester.enterText(_dialogField, '재즈');
    await tester.tap(find.text('바꾸기'));
    await tester.pumpAndSettle();
    // 적용 전 확인창.
    expect(find.textContaining('고른 2곡의 장르가 "재즈"'), findsOneWidget);
    await tester.tap(find.text('바꾸기'));
    await tester.pumpAndSettle();

    // 선택 모드가 끝나고, 장르 탭에 재즈(2곡)와 락(1곡)이 나뉜다.
    expect(find.text('2곡 선택'), findsNothing);
    await tester.tap(find.text('장르'));
    await tester.pumpAndSettle();
    expect(find.text('재즈'), findsOneWidget);
    expect(find.text('2곡'), findsOneWidget);
    expect(find.text('락'), findsOneWidget);
  });

  testWidgets('확인창에서 취소하면 아무것도 바뀌지 않고 선택이 남는다', (tester) async {
    await pumpLibrary(tester);
    await tester.longPress(find.text('첫 곡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범 지정'));
    await tester.pumpAndSettle();
    await tester.enterText(_dialogField, '새 앨범');
    await tester.tap(find.text('바꾸기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('1곡 선택'), findsOneWidget);
    await tester.tap(find.byTooltip('선택 끝내기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('새 앨범'), findsNothing);
  });
}
