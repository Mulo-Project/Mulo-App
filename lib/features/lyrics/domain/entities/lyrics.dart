import 'package:equatable/equatable.dart';

/// 싱크 가사의 한 줄: [time]부터 [text]를 보여 준다.
class LyricLine extends Equatable {
  const LyricLine(this.time, this.text);

  final Duration time;
  final String text;

  @override
  List<Object?> get props => [time, text];
}

/// 곡 하나의 가사. [raw]는 저장된 원문(.lrc 또는 일반 글).
/// 시간 표시(`[01:02.30]`)가 하나라도 있으면 싱크 가사 ([lines]), 없으면 일반 글 ([plain]).
class Lyrics extends Equatable {
  const Lyrics._(this.raw, this.lines, this.plain);

  /// [raw]를 읽어 가사를 만든다. 내용이 비면 null.
  static Lyrics? parse(String raw) {
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.trim().isEmpty) return null;

    var offset = Duration.zero;
    final lines = <LyricLine>[];
    final plain = <String>[];
    for (final line in text.split('\n')) {
      final stamps = <Duration>[];
      var rest = line.trimLeft();
      Match? m;
      while ((m = _stamp.matchAsPrefix(rest)) != null) {
        stamps.add(
          Duration(
            milliseconds:
                int.parse(m!.group(1)!) * 60000 +
                int.parse(m.group(2)!) * 1000 +
                _fraction(m.group(3)),
          ),
        );
        rest = rest.substring(m.end).trimLeft();
      }
      if (stamps.isEmpty) {
        final tag = _tag.firstMatch(line.trim());
        if (tag != null) {
          // [offset:+500] 같은 메타 태그: 줄 시간을 그만큼 앞당긴다. 나머지 태그는 가사가 아니다.
          if (tag.group(1)!.toLowerCase() == 'offset') {
            offset = Duration(
              milliseconds: int.tryParse(tag.group(2)!.trim()) ?? 0,
            );
          }
          continue;
        }
        plain.add(line.trimRight());
        continue;
      }
      final body = rest.trimRight();
      for (final t in stamps) {
        lines.add(LyricLine(t, body));
      }
      plain.add(body);
    }

    final plainText = plain.join('\n').trim();
    if (lines.isEmpty) return Lyrics._(raw, const [], plainText);
    final shifted = [
      for (final l in lines)
        LyricLine(
          l.time - offset < Duration.zero ? Duration.zero : l.time - offset,
          l.text,
        ),
    ]..sort((a, b) => a.time.compareTo(b.time));
    return Lyrics._(raw, shifted, plainText);
  }

  static final _stamp = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
  static final _tag = RegExp(r'^\[([A-Za-z]+):(.*)\]$');

  /// `5` → 500ms, `30` → 300ms, `123` → 123ms.
  static int _fraction(String? digits) =>
      digits == null ? 0 : int.parse(digits.padRight(3, '0'));

  final String raw;

  /// 싱크 가사 줄 (시간 순). 일반 글이면 빈 목록.
  final List<LyricLine> lines;

  /// 시간 표시를 뺀 글 (일반 글 보기용).
  final String plain;

  bool get isSynced => lines.isNotEmpty;

  /// [position]에 맞는 줄의 번호. 첫 줄 시간 전이면 -1.
  int currentLine(Duration position) {
    var lo = 0, hi = lines.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time <= position) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found;
  }

  @override
  List<Object?> get props => [raw];
}
