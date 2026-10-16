import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/timed_lyrics_text.dart';

void main() {
  const raw = '[00:01.00]one\n[00:02.50]two\nthree';

  test('싱크 가사를 시간과 글로 나눈다', () {
    final split = TimedLyricsText.parse(raw);
    expect(split.text, 'one\ntwo\nthree');
    expect(split.times, [
      const Duration(seconds: 1),
      const Duration(seconds: 2, milliseconds: 500),
    ]);
  });

  test('일반 글은 그대로이고 시간이 없다', () {
    final split = TimedLyricsText.parse('a\nb');
    expect(split.isSynced, isFalse);
    expect(split.text, 'a\nb');
    expect(split.compose('a\nb c'), 'a\nb c');
  });

  test('줄 번호로 시간을 다시 붙인다: 끼우면 글만 밀리고 남는 줄은 시간이 없다', () {
    final split = TimedLyricsText.parse(raw);
    expect(
      split.compose('one!\ntwo\nthree'),
      '[00:01.00]one!\n[00:02.50]two\nthree',
    );
    expect(
      split.compose('zero\none\ntwo'),
      '[00:01.00]zero\n[00:02.50]one\ntwo',
    );
    expect(split.compose('only'), '[00:01.00]only');
  });

  test('글을 모두 지우면 가사가 비워진다', () {
    expect(TimedLyricsText.parse(raw).compose('  \n'), '');
  });
}
