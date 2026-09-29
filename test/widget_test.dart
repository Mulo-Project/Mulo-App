import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  String at = Routes.library,
  double height = 2532,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(1170, height);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.localesTestValue = const [Locale('ko')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(ProviderScope(child: MusicApp(initialLocation: at)));
  await tester.pumpAndSettle();
}

AppPalette _palette(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(AppBottomNav)))
        .extension<AppThemeTokens>()!
        .palette;

void main() {
  testWidgets('보관함에서 시작하고 하단 탭으로 이동한다', (tester) async {
    await _pumpApp(tester);
    expect(find.text('보관함'), findsWidgets);
    expect(find.byType(MiniPlayerBar), findsOneWidget);

    await tester.tap(find.text('다운로드').last);
    await tester.pumpAndSettle();
    expect(find.text('대기열'.toUpperCase()), findsOneWidget);
  });

  testWidgets('설정에서 테마 프리셋을 고르면 팔레트가 바뀐다', (tester) async {
    await _pumpApp(tester, at: Routes.settings, height: 7000);
    expect(_palette(tester).accent, AppPalette.lime);

    await tester.tap(find.text('코랄'));
    await tester.pumpAndSettle();
    expect(_palette(tester).accent, isNot(AppPalette.lime));
    expect(_palette(tester).background, AppPalette.black);

    await tester.tap(find.text('바이올렛'));
    await tester.pumpAndSettle();
    expect(_palette(tester).accent, AppPalette.lime);
  });

  testWidgets('미니 플레이어를 누르면 전체 화면 플레이어가 열린다', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byType(MiniPlayerBar));
    await tester.pumpAndSettle();
    expect(find.text('지금 재생 중'), findsOneWidget);
  });

  test('derive는 강조 색 대비를 보정한다', () {
    final p = AppPalette.derive(
      primary: const Color(0xFF220044),
      accent: const Color(0xFF111133),
    );
    expect(contrastRatio(p.accent, p.background), greaterThanOrEqualTo(7));
    expect(p.background, AppPalette.black);
  });
}
