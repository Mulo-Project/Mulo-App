import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';

Widget _host(String text, {double width = 120, bool scroll = true}) =>
    MaterialApp(
      theme: buildAppTheme(AppPalette.defaultDark),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MarqueeText(text, scroll: scroll),
          ),
        ),
      ),
    );

void main() {
  testWidgets('칸에 들어가는 제목은 움직이지 않고 그냥 글자로 보인다', (tester) async {
    await tester.pumpWidget(_host('짧은 곡'));
    await tester.pump();
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('칸보다 긴 제목은 흘러가고, 글자를 바꾸면 다시 맞춘다', (tester) async {
    await tester.pumpWidget(_host('아주 아주 아주 아주 긴 곡 제목이라서 한 줄에 다 들어가지 않습니다'));
    await tester.pump();
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(_host('짧은 곡'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // 테마 전환 애니메이션이 끝나도록
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('scroll을 끄면 넘쳐도 …로 줄이고 움직이지 않는다', (tester) async {
    await tester.pumpWidget(
      _host('아주 아주 아주 아주 긴 곡 제목이라서 한 줄에 다 들어가지 않습니다', scroll: false),
    );
    await tester.pump();
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
