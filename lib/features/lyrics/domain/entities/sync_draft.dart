import 'package:equatable/equatable.dart';

import 'lyrics.dart';

/// 싱크 맞추기 작업 중인 가사: 줄마다 시간을 찍어 간다.
/// [current]는 다음에 시간을 찍을 줄, 끝까지 찍었으면 줄 수와 같다.
class SyncDraft extends Equatable {
  const SyncDraft._(this.texts, this.times, this.current, this._history);

  /// [lyrics]의 빈 줄을 뺀 줄로 시작한다. 이미 싱크 가사면 그 시간을 이어받는다.
  factory SyncDraft.from(Lyrics lyrics) {
    if (lyrics.isSynced) {
      final lines = [
        for (final l in lyrics.lines)
          if (l.text.isNotEmpty) l,
      ];
      return SyncDraft._(
        [for (final l in lines) l.text],
        [for (final l in lines) l.time],
        lines.length,
        const [],
      );
    }
    final texts = [
      for (final line in lyrics.plain.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    return SyncDraft._(texts, List.filled(texts.length, null), 0, const []);
  }

  final List<String> texts;
  final List<Duration?> times;
  final int current;
  final List<_Snapshot> _history;

  int get length => texts.length;
  int get stamped => times.whereType<Duration>().length;
  bool get isComplete => length > 0 && stamped == length;
  bool get canUndo => _history.isNotEmpty;

  /// 지금 위치를 [current] 줄에 찍고 다음 줄로 넘어간다. 끝났으면 그대로.
  SyncDraft stamp(Duration position) {
    if (current >= length) return this;
    return _change(
      times: [...times]..[current] = _clamp(position),
      current: current + 1,
    );
  }

  /// [index] 줄의 시간을 [delta]만큼 옮긴다. 찍지 않은 줄이면 그대로.
  SyncDraft nudge(int index, Duration delta) {
    final t = index < 0 || index >= length ? null : times[index];
    if (t == null) return this;
    return _change(
      times: [...times]..[index] = _clamp(t + delta),
      current: current,
    );
  }

  /// 다음에 찍을 줄을 [index]로 옮긴다 (이미 찍은 시간은 그대로).
  SyncDraft moveTo(int index) => index < 0 || index > length || index == current
      ? this
      : _change(times: times, current: index);

  /// 직전 변경을 되돌린다.
  SyncDraft undo() {
    if (_history.isEmpty) return this;
    final last = _history.last;
    return SyncDraft._(
      texts,
      last.times,
      last.current,
      _history.sublist(0, _history.length - 1),
    );
  }

  /// `[mm:ss.xx]가사` 줄로 합친 글. 모든 줄을 찍었을 때만 의미가 있다.
  String toLrc() => [
    for (var i = 0; i < length; i++)
      if (times[i] != null) '${formatStamp(times[i]!)}${texts[i]}',
  ].join('\n');

  /// `01:02.30`에 대괄호를 씌운 LRC 시간 표시 (1/100초 단위).
  static String formatStamp(Duration d) {
    final cs = (d.inMilliseconds / 10).round();
    final m = cs ~/ 6000;
    final s = (cs ~/ 100) % 60;
    final f = cs % 100;
    return '[${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.${f.toString().padLeft(2, '0')}]';
  }

  static Duration _clamp(Duration d) => d < Duration.zero ? Duration.zero : d;

  SyncDraft _change({required List<Duration?> times, required int current}) =>
      SyncDraft._(texts, times, current, [
        ..._history,
        _Snapshot(this.times, this.current),
      ]);

  @override
  List<Object?> get props => [texts, times, current];
}

class _Snapshot {
  const _Snapshot(this.times, this.current);

  final List<Duration?> times;
  final int current;
}
