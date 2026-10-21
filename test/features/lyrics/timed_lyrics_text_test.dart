import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/timed_lyrics_text.dart';
import 'package:music_download_play_app/features/lyrics/presentation/widgets/timed_lyrics_controller.dart';

void main() {
  _controllerOps();
  const raw = '[00:01.00]one\n[00:02.50]two\nthree';

  test('싱크 가사를 시간과 글로 나눈다 (시간 없는 뒷줄은 null)', () {
    final split = TimedLyricsText.parse(raw);
    expect(split.text, 'one\ntwo\nthree');
    expect(split.times, [
      const Duration(seconds: 1),
      const Duration(seconds: 2, milliseconds: 500),
      null,
    ]);
  });

  test('일반 글은 그대로이고 시간이 없다', () {
    final split = TimedLyricsText.parse('a\nb');
    expect(split.isSynced, isFalse);
    expect(split.text, 'a\nb');
    expect(split.compose('a\nb c'), 'a\nb c');
  });

  test('글을 모두 지우면 가사가 비워진다', () {
    expect(TimedLyricsText.parse(raw).compose('  \n'), '');
  });

  group('remapTimes', () {
    const t1 = Duration(seconds: 1);
    const t2 = Duration(seconds: 2);
    const t3 = Duration(seconds: 3);

    test('한 줄 안을 고치면 시간은 그대로', () {
      expect(
        TimedLyricsText.remapTimes(['a', 'b', 'c'], ['a', 'B!', 'c'], [
          t1,
          t2,
          t3,
        ]),
        [t1, t2, t3],
      );
    });

    test('줄을 끼우면 새 줄은 바로 위 줄의 시간을 물려받고 아래 줄은 제 시간을 지킨다', () {
      expect(
        TimedLyricsText.remapTimes(['a', 'b'], ['a', 'x', 'b'], [t1, t3]),
        [t1, t1, t3],
      );
      // 맨 앞에 끼우면 아래 줄의 시간을 물려받는다.
      expect(
        TimedLyricsText.remapTimes(['a', 'b'], ['x', 'a', 'b'], [t1, t3]),
        [t1, t1, t3],
      );
    });

    test('줄을 지우면 그 줄의 시간만 사라진다', () {
      expect(
        TimedLyricsText.remapTimes(['a', 'b', 'c'], ['a', 'c'], [t1, t2, t3]),
        [t1, t3],
      );
    });

    test('줄 가운데서 줄바꿈하면 두 줄이 같은 시간으로 묶인다', () {
      expect(
        TimedLyricsText.remapTimes(['abcdef', 'z'], ['abc', 'def', 'z'], [
          t1,
          t3,
        ]),
        [t1, t1, t3],
      );
    });
  });

  test('컨트롤러: 글을 고치며 줄을 끼워도 시간이 제 줄을 따라가고 저장 글에 다시 붙는다', () {
    final c = TimedLyricsController()..load(TimedLyricsText.parse(raw));
    c.text = 'one\n끼움\ntwo\nthree';
    expect(c.compose(), '[00:01.00]one\n[00:01.00]끼움\n[00:02.50]two\nthree');
    c.dispose();
  });
}

void _controllerOps() {
  const t1 = Duration(seconds: 1);
  const t2 = Duration(seconds: 2);
  const t3 = Duration(seconds: 3);

  TimedLyricsController make() => TimedLyricsController()
    ..load(
      TimedLyricsText.parse(
        '[00:01.00]a\n[00:02.00]b\n[00:03.00]c\n[00:03.00]d',
      ),
    );

  group('줄 싱크 조절', () {
    test('adjust는 이웃 줄의 시간을 넘지 않는다', () {
      final c = make();
      c.adjust(1, const Duration(milliseconds: 300));
      expect(c.times[1], const Duration(milliseconds: 2300));
      c.adjust(1, const Duration(seconds: 5));
      expect(c.times[1], t3);
      c.adjust(1, const Duration(seconds: -5));
      expect(c.times[1], t1);
      c.dispose();
    });

    test('위 줄과 묶기 · 묶음에서 떼기', () {
      final c = make();
      c.groupWithAbove(1);
      expect(c.times, [t1, t1, t3, t3]);
      expect(c.isGroupedWithAbove(1), isTrue);
      c.separate(3);
      // 같은 묶음의 끝까지(여기서는 3번 줄 하나)가 다음 시간이 없으니 0.5초 뒤로 떨어진다.
      expect(c.times[3], const Duration(milliseconds: 3500));
      expect(c.times[2], t3);
      c.dispose();
    });

    test('여기부터 싱크 지우기는 아래 모든 줄의 시간을 지운다', () {
      final c = make();
      c.clearFrom(2);
      expect(c.times, [t1, t2, null, null]);
      expect(c.compose(), '[00:01.00]a\n[00:02.00]b\nc\nd');
      c.dispose();
    });
  });
}
