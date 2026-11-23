import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';

Widget _host(List<String> labels) => MaterialApp(
  theme: buildAppTheme(AppPalette.defaultDark),
  home: Scaffold(
    body: AppDialog(
      title: '제목',
      actions: [for (final l in labels) PillButton(label: l, onPressed: () {})],
    ),
  ),
);

void main() {
  testWidgets('버튼 글자가 짧으면 가로로 나란히 놓는다', (tester) async {
    await tester.pumpWidget(_host(['취소', '확인']));
    final a = tester.getTopLeft(find.text('취소')).dy;
    final b = tester.getTopLeft(find.text('확인')).dy;
    expect(a, b);
  });

  testWidgets('버튼 글자가 잘릴 만큼 길면 세로로 쌓는다', (tester) async {
    await tester.pumpWidget(
      _host(['저장하지 않고 이대로 그냥 나가기 버튼입니다', '저장하고 나가서 나중에 이어서 하기']),
    );
    final a = tester.getTopLeft(find.textContaining('저장하지')).dy;
    final b = tester.getTopLeft(find.textContaining('저장하고')).dy;
    expect(b, greaterThan(a));
  });
}
