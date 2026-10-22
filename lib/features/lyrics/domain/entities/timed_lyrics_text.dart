import 'lyrics.dart';

/// `mm:ss.xx` 모양의 시간 글자 (싱크 가사의 시간 표시와 같은 모양).
String lyricTimeLabel(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  final cs = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
  return '$m:$s.$cs';
}

/// 편집용으로 나눈 가사: 시간 표시를 뺀 글 한 덩어리 + 줄마다 따로 든 시간.
///
/// 싱크 가사를 `[01:02.30]글`로 그대로 고치면 시간 표시가 깨지기 쉬워서, 편집 중에는
/// 글([text])과 시간([times])을 따로 둔다. 글을 고칠 때마다 [remapTimes]로 줄을 끼우거나
/// 지운 것을 알아내 시간이 제 줄을 따라가게 한다. 새로 끼운 줄은 바로 위 줄의 시간을 물려받아
/// 그 줄과 한 묶음이 된다 (정확한 시간은 싱크 화면에서 맞춘다).
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
      [
        for (final l in lyrics.lines) l.time,
        for (final _ in lyrics.pending) null,
      ],
    );
  }

  /// 시간 표시가 없는 글.
  final String text;

  /// 줄마다의 시간 (`times[i]`가 `i`번째 줄의 시간, 없으면 null). 줄 수보다 짧을 수 있다.
  final List<Duration?> times;

  bool get isSynced => times.any((t) => t != null);

  /// 고친 글 [edited]에 줄마다의 시간을 다시 붙여 저장할 글로 만든다.
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
      final at = i < times.length ? times[i] : null;
      b.writeln(at == null ? line : '[${lyricTimeLabel(at)}]$line');
    }
    return b.toString().trimRight();
  }

  /// 줄이 [oldLines]에서 [newLines]로 바뀔 때 줄마다의 시간을 옮긴다.
  /// 앞뒤로 그대로인 줄은 시간을 지키고, 가운데가 같은 줄 수로 고쳐졌으면 그 자리 시간을 지킨다.
  /// 줄이 늘었으면 새 줄은 바로 위 줄(맨 앞이면 아래 줄)의 시간을 물려받고,
  /// 줄이 줄었으면 지워진 줄의 시간이 사라진다.
  static List<Duration?> remapTimes(
    List<String> oldLines,
    List<String> newLines,
    List<Duration?> oldTimes,
  ) {
    final old = [
      for (var i = 0; i < oldLines.length; i++)
        i < oldTimes.length ? oldTimes[i] : null,
    ];
    final limit = oldLines.length < newLines.length
        ? oldLines.length
        : newLines.length;
    var p = 0;
    while (p < limit && oldLines[p] == newLines[p]) {
      p++;
    }
    var s = 0;
    while (s < limit - p &&
        oldLines[oldLines.length - 1 - s] ==
            newLines[newLines.length - 1 - s]) {
      s++;
    }
    final oldMid = oldLines.length - p - s;
    final newMid = newLines.length - p - s;
    final out = <Duration?>[...old.take(p)];
    for (var k = 0; k < newMid; k++) {
      if (k < oldMid) {
        out.add(old[p + k]);
      } else if (out.isNotEmpty) {
        out.add(out.last);
      } else {
        out.add(p + oldMid < old.length ? old[p + oldMid] : null);
      }
    }
    out.addAll(old.skip(oldLines.length - s));
    return out;
  }
}
