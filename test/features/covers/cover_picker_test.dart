import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/covers/presentation/widgets/cover_picker.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('이미지 고르기 시트에 기기와 웹 선택이 모두 보인다', (tester) async {
    await setUpTestDependencies();
    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(MusicApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    pickCoverArt(context);
    await tester.pumpAndSettle();

    expect(find.text('기기에서 고르기'), findsOneWidget);
    expect(find.text('웹에서 가져오기'), findsOneWidget);
    final box = tester.getRect(find.text('웹에서 가져오기'));
    debugPrint('web rect $box');
  });
}
