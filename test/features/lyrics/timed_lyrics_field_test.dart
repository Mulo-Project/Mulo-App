import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/timed_lyrics_text.dart';
import 'package:music_download_play_app/features/lyrics/presentation/widgets/timed_lyrics_controller.dart';
import 'package:music_download_play_app/features/lyrics/presentation/widgets/timed_lyrics_field.dart';

void main() {
  testWidgets('싱크 시간 칸은 접히는 긴 줄이 있어도 글 줄과 같은 높이에 선다', (tester) async {
    final controller = TimedLyricsController()
      ..load(
        TimedLyricsText.parse(
          '[00:01.00]짧은 줄\n'
          '[00:02.00]이 줄은 아주 길어서 좁은 화면에서는 두 줄 세 줄로 접혀야 하고 그 뒤 줄들의 시간이 밀리면 안 돼요\n'
          '[00:03.00]세 번째 줄\n'
          '[00:04.00]네 번째 줄',
        ),
      );
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AppPalette.defaultDark),
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: TimedLyricsField(controller: controller, showTimes: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final editable = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    // 줄이 시작하는 글자 위치.
    final text = controller.text;
    final starts = <int>[];
    var from = 0;
    for (final line in text.split('\n')) {
      starts.add(from);
      from += line.length + 1;
    }
    for (var i = 0; i < starts.length; i++) {
      final caret = editable.getLocalRectForCaret(
        TextPosition(offset: starts[i]),
      );
      final textTop = editable.localToGlobal(caret.topLeft).dy;
      final label = find.text(
        ['00:01.00', '00:02.00', '00:03.00', '00:04.00'][i],
      );
      expect(label, findsOneWidget);
      // 글 줄의 높이는 줄 높이(2배) 가운데에 커서가 서므로 시간 글자의 위쪽과 같은 줄 안에 있어야 한다.
      final labelTop = tester.getTopLeft(label).dy;
      expect((labelTop - textTop).abs(), lessThan(14), reason: '$i번 줄');
    }
  });

  testWidgets('줄 끝에서 커서 자리만큼 먼저 접혀도 시간이 한 줄씩 밀리지 않는다', (tester) async {
    // 시험용 글꼴은 글자 폭이 글자 크기와 같다. 13px로 20자면 입력칸 폭(260)에 딱 맞아 보이지만,
    // 입력칸은 커서 자리(3px)만큼 먼저 접으므로 실제로는 두 줄이 된다.
    final controller = TimedLyricsController()
      ..load(
        TimedLyricsText.parse(
          '[00:01.00]${'a' * 20}\n[00:02.00]다음 줄\n[00:03.00]마지막',
        ),
      );
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final base = buildAppTheme(AppPalette.defaultDark);
    await tester.pumpWidget(
      MaterialApp(
        theme: base.copyWith(
          textTheme: base.textTheme.copyWith(
            bodyMedium: base.textTheme.bodyMedium!.copyWith(fontSize: 13),
          ),
        ),
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: TimedLyricsField(controller: controller, showTimes: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final editable = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    final starts = [0, 21, 21 + 5];
    final labels = ['00:01.00', '00:02.00', '00:03.00'];
    for (var i = 0; i < starts.length; i++) {
      final caret = editable.getLocalRectForCaret(
        TextPosition(offset: starts[i]),
      );
      final textTop = editable.localToGlobal(caret.topLeft).dy;
      final labelTop = tester.getTopLeft(find.text(labels[i])).dy;
      expect((labelTop - textTop).abs(), lessThan(14), reason: '${i + 1}번 줄');
    }
  });
}
