import 'package:flutter/widgets.dart';

import '../../domain/entities/timed_lyrics_text.dart';

/// 글 한 덩어리를 고치며 줄마다의 싱크 시간을 함께 들고 있는 입력 컨트롤러.
/// 글이 바뀔 때마다 줄을 끼우거나 지운 것을 알아내 시간이 제 줄을 따라가게 한다 ([TimedLyricsText.remapTimes]).
class TimedLyricsController extends TextEditingController {
  TimedLyricsController() {
    addListener(_onChange);
  }

  /// 줄마다의 시간 (없으면 null). 글의 줄 수와 같게 유지된다.
  List<Duration?> times = [];
  var _lines = <String>[''];

  /// 묶음마다 돌려 쓰는 색 (화면이 정한다). 비어 있으면 글자색을 바꾸지 않는다.
  List<Color> groupPalette = const [];

  /// [i]번 줄이 두 줄 이상 묶음이면 그 묶음의 색, 아니면 null. 시간 칸과 글이 같은 색을 쓴다.
  Color? groupColor(int i) {
    if (groupPalette.isEmpty || i < 0 || i >= times.length) return null;
    final t = times[i];
    if (t == null) return null;
    var start = i;
    while (start > 0 && times[start - 1] == t) {
      start--;
    }
    var end = i;
    while (end + 1 < times.length && times[end + 1] == t) {
      end++;
    }
    if (start == end) return null;
    var n = 0;
    var j = 0;
    while (j < start) {
      var k = j;
      while (k + 1 < start && times[k + 1] == times[j] && times[j] != null) {
        k++;
      }
      if (k > j) n++;
      j = k + 1;
    }
    return groupPalette[n % groupPalette.length];
  }

  bool get isSynced => times.any((t) => t != null);

  /// 나눈 가사로 글과 시간을 한꺼번에 채운다.
  void load(TimedLyricsText split) {
    times = [...split.times];
    _lines = split.text.split('\n');
    // 글을 넣는 것은 줄 편집이 아니므로 시간을 다시 계산하지 않는다.
    value = TextEditingValue(text: split.text);
    _lines = split.text.split('\n');
  }

  /// 저장할 글: 줄마다의 시간을 `[mm:ss.xx]`로 다시 붙인다.
  String compose() => TimedLyricsText(text, times).compose(text);

  /// [i]번 줄의 시간을 [delta]만큼 옮긴다. 앞 줄과 다음 줄의 시간 사이를 넘지 않는다 (순서 유지).
  void adjust(int i, Duration delta) {
    if (i < 0 || i >= times.length || times[i] == null) return;
    setTime(i, times[i]! + delta);
  }

  /// [i]번 줄의 시간을 [to]로 바꾼다. 앞 줄과 다음 줄의 시간 사이로 맞춘다.
  void setTime(int i, Duration to) {
    if (i < 0 || i >= times.length || times[i] == null) return;
    var next = to;
    if (next < Duration.zero) next = Duration.zero;
    final prev = i > 0 ? times[i - 1] : null;
    final after = i + 1 < times.length ? times[i + 1] : null;
    if (prev != null && next < prev) next = prev;
    if (after != null && next > after) next = after;
    times[i] = next;
    notifyListeners();
  }

  /// [from]~[to] 줄(순서 무관)을 맨 위 줄의 시간으로 묶는다. 맨 위 줄에 시간이 없으면 그대로.
  void groupRange(int from, int to) {
    final a = from < to ? from : to;
    final b = from < to ? to : from;
    if (a < 0 || b >= times.length || a == b || times[a] == null) return;
    for (var j = a + 1; j <= b; j++) {
      times[j] = times[a];
    }
    notifyListeners();
  }

  /// [i]번 줄이 위 줄과 묶여 있는가.
  bool isGroupedWithAbove(int i) =>
      i > 0 && i < times.length && times[i] != null && times[i] == times[i - 1];

  /// [i]번 줄부터 같은 묶음 끝까지를 위 줄들에서 떼어 낸다. 새 시간은 다음 다른 시간과의 가운데
  /// (다음이 없으면 0.5초 뒤)라서, 이어서 [adjust]로 다듬으면 된다.
  void separate(int i) {
    if (!isGroupedWithAbove(i)) return;
    final old = times[i]!;
    var end = i;
    while (end + 1 < times.length && times[end + 1] == old) {
      end++;
    }
    Duration? later;
    for (var j = end + 1; j < times.length; j++) {
      if (times[j] != null && times[j] != old) {
        later = times[j];
        break;
      }
    }
    final next = later == null
        ? old + const Duration(milliseconds: 500)
        : old + (later - old) ~/ 2;
    for (var j = i; j <= end; j++) {
      times[j] = next;
    }
    notifyListeners();
  }

  /// [i]번 줄부터 아래 모든 줄의 시간을 지운다 (뒤쪽은 시간 없는 글로 남아 나중에 이어서 찍는다).
  /// 시간 없는 줄은 맨 뒤쪽에만 둘 수 있어서 중간만 지우지는 않는다.
  void clearFrom(int i) {
    if (i < 0 || i >= times.length) return;
    for (var j = i; j < times.length; j++) {
      times[j] = null;
    }
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final lines = text.split('\n');
    final colors = [for (var i = 0; i < lines.length; i++) groupColor(i)];
    if (colors.every((c) => c == null) ||
        (withComposing && value.composing.isValid)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return TextSpan(
      style: style,
      children: [
        for (var i = 0; i < lines.length; i++)
          TextSpan(
            text: i == lines.length - 1 ? lines[i] : '${lines[i]}\n',
            style: colors[i] == null ? null : TextStyle(color: colors[i]),
          ),
      ],
    );
  }

  void _onChange() {
    final next = text.split('\n');
    if (next.length == _lines.length) {
      var same = true;
      for (var i = 0; i < next.length; i++) {
        if (next[i] != _lines[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    times = TimedLyricsText.remapTimes(_lines, next, times);
    _lines = next;
  }
}
