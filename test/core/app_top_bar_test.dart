import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';

Widget _host(List<Widget> actions, {String title = '아주 아주 긴 앨범 이름이 들어가는 제목'}) =>
    MaterialApp(
      theme: buildAppTheme(AppPalette.defaultDark),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            child: AppTopBar(
              title: title,
              leading: CircleIconButton(
                icon: AppIcons.back,
                tooltip: '뒤로',
                onPressed: () {},
              ),
              actions: actions,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('버튼이 둘이어도 제목이 버튼과 겹치지 않고 넘치지 않는다', (tester) async {
    await tester.pumpWidget(
      _host([
        CircleIconButton(icon: AppIcons.edit, tooltip: '이름', onPressed: () {}),
        CircleIconButton(
          icon: AppIcons.sparkle,
          tooltip: '꾸미기',
          onPressed: () {},
        ),
      ]),
    );
    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.textContaining('아주 아주'));
    final back = tester.getRect(find.byTooltip('뒤로'));
    final edit = tester.getRect(find.byTooltip('이름'));
    expect(title.left, greaterThanOrEqualTo(back.right));
    expect(title.right, lessThanOrEqualTo(edit.left));
  });

  testWidgets('버튼이 하나 이하면 제목은 화면 가운데에 있다', (tester) async {
    await tester.pumpWidget(_host(const [], title: '짧은 제목'));
    final title = tester.getRect(find.text('짧은 제목'));
    expect((title.center.dx - 180).abs(), lessThan(1));
  });
}
