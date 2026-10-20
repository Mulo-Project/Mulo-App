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
