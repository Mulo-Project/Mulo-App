import 'lyrics.dart';

/// `mm:ss.xx` 모양의 시간 글자 (싱크 가사의 시간 표시와 같은 모양).
String lyricTimeLabel(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  final cs = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
  return '$m:$s.$cs';
}

/// 편집용으로 나눈 가사: 시간 표시를 뺀 글 한 덩어리 + 줄 번호별 시간.
///
/// 싱크 가사를 `[01:02.30]글`로 그대로 고치면 시간 표시가 깨지기 쉬워서, 편집 중에는
/// 글([text])과 시간([times])을 따로 두고 **줄 번호**로 짝짓는다. 줄을 끼우거나 지우면
/// 시간은 그 번호 자리에 남고 글만 밀린다. 시간보다 많은 줄은 시간 없는 줄이 된다.
class TimedLyricsText {
  const TimedLyricsText(this.text, this.times);

  /// [raw](.lrc 또는 일반 글)를 나눈다. 싱크 가사가 아니면 시간은 비어 있고 글은 [raw] 그대로다.
  factory TimedLyricsText.parse(String raw) {
    final lyrics = Lyrics.parse(raw);
    if (lyrics == null || !lyrics.isSynced) {
      return TimedLyricsText(raw, const []);
    }
    return TimedLyricsText(
      [for (final l in lyrics.lines) l.text, ...lyrics.pending].join('\n'),
      [for (final l in lyrics.lines) l.time],
    );
  }

  /// 시간 표시가 없는 글.
  final String text;

  /// 줄 번호별 시간 (`times[i]`가 `i`번째 줄의 시간).
  final List<Duration> times;

  bool get isSynced => times.isNotEmpty;

  /// 고친 글 [edited]에 줄 번호에 맞는 시간을 다시 붙여 저장할 글로 만든다.
  String compose(String edited) {
    // 글을 모두 지우면 시간만 남기지 않고 가사를 비운다.
    if (edited.trim().isEmpty) {
      return '';
    }
    if (!isSynced) {
      return edited;
    }
    final lines = edited.replaceAll('\r\n', '\n').split('\n');
    final b = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      b.writeln(i < times.length ? '[${lyricTimeLabel(times[i])}]$line' : line);
    }
    return b.toString().trimRight();
  }
}
