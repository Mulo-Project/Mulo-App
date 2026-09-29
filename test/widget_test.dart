import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/core/design/design.dart';

void main() {
  testWidgets('디자인 미리보기가 뜨고 대체 팔레트로 바뀐다', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: MusicApp()));
    expect(find.text('미리보기'), findsOneWidget);

    AppPalette current() =>
        Theme.of(tester.element(find.text('미리보기')))
            .extension<AppThemeTokens>()!
            .palette;

    expect(current().accent, AppPalette.lime);

    await tester.tap(find.text('대체 팔레트'));
    await tester.pumpAndSettle();
    expect(current().accent, isNot(AppPalette.lime));
    expect(current().background, AppPalette.black);

    await tester.tap(find.text('기본'));
    await tester.pumpAndSettle();
    expect(current().accent, AppPalette.lime);
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
