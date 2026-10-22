import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/covers/presentation/widgets/cover_picker.dart';

import '../../helpers/fakes.dart';

Future<BuildContext> _open(WidgetTester tester) async {
  await setUpTestDependencies();
  tester.view.physicalSize = const Size(1170, 2400);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.localesTestValue = const [Locale('ko')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(MusicApp(initialLocation: Routes.settings));
  await tester.pumpAndSettle();
  return tester.element(find.byType(Scaffold).first);
}

void main() {
  testWidgets('이미지 고르기는 편집 화면을 먼저 띄우고, 위쪽에 기기와 웹 버튼이 있다', (tester) async {
    final context = await _open(tester);
    pickCoverArt(context);
    await tester.pumpAndSettle();

    expect(find.text('이미지 위치'), findsOneWidget);
    expect(find.text('기기에서 고르기'), findsOneWidget);
    expect(find.text('웹에서 가져오기'), findsOneWidget);
    expect(find.byKey(const ValueKey('cover-edit-empty')), findsOneWidget);
    expect(find.text('위에서 이미지를 불러오세요'), findsOneWidget);
  });

  testWidgets('이미 있는 이미지를 편집하면 그 이미지를 불러온 채로 열린다', (tester) async {
    final context = await _open(tester);
    pickCoverArt(context, current: CoverArt.web('https://x.test/a.jpg'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('이미지 위치'), findsOneWidget);
    expect(find.text('위에서 이미지를 불러오세요'), findsNothing);
  });
}
