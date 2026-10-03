import 'package:equatable/equatable.dart';

import 'lyrics.dart';

/// 싱크 맞추기 작업 중인 가사: 줄마다 시간을 찍어 간다.
/// 원본 줄 [lines]를 [sizes]만큼씩 이어 붙인 것이 싱크 한 칸([texts])이다.
/// [current]는 다음에 시간을 찍을 칸, 끝까지 찍었으면 칸 수와 같다.
class SyncDraft extends Equatable {
  SyncDraft._(this.lines, this.sizes, this.times, this.current, this._history)
    : texts = _join(lines, sizes);

  /// [lyrics]의 빈 줄을 뺀 줄로 시작한다. 이미 싱크 가사면 그 시간을 이어받는다.
  /// 일반 글이면 [group]줄씩 하나로 묶어 한 번에 시간을 찍는다 (묶인 줄은 공백으로 이어 붙인다).
  factory SyncDraft.from(Lyrics lyrics, {int group = 1}) {
    if (lyrics.isSynced) {
      final lines = [
        for (final l in lyrics.lines)
          if (l.text.isNotEmpty) l,
      ];
      return SyncDraft._(
        [for (final l in lines) l.text],
        List.filled(lines.length, 1),
        [for (final l in lines) l.time],
        lines.length,
        const [],
      );
    }
    final lines = [
      for (final line in lyrics.plain.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    final sizes = defaultSizes(lines.length, group);
    return SyncDraft._(
      lines,
      sizes,
      List.filled(sizes.length, null),
      0,
      const [],
    );
  }

  /// [count]줄을 [group]줄씩 나눈 칸 크기 (마지막 칸은 모자랄 수 있다).
  static List<int> defaultSizes(int count, int group) {
    final size = group < 1 ? 1 : group;
    return [
      for (var i = 0; i < count; i += size)
        i + size <= count ? size : count - i,
    ];
  }

  final List<String> lines;
  final List<int> sizes;
  final List<String> texts;
  final List<Duration?> times;
  final int current;
  final List<_Snapshot> _history;

  int get length => texts.length;
  int get stamped => times.whereType<Duration>().length;
  bool get isComplete => length > 0 && stamped == length;
  bool get canUndo => _history.isNotEmpty;

  /// [index] 칸이 시작하는 원본 줄 번호.
  int startOf(int index) => sizes.take(index).fold(0, (a, b) => a + b);

  /// 기본 [group]줄 나눔과 다르게 묶은 칸이 있는가.
  bool isCustom(int group) {
    final base = defaultSizes(lines.length, group);
    if (base.length != sizes.length) return true;
    for (var i = 0; i < base.length; i++) {
      if (base[i] != sizes[i]) return true;
    }
    return false;
  }

  /// [index] 칸을 원본 [endLine] 줄까지로 다시 묶는다. 이 칸이 삼킨 칸과 남는 줄의 시간은 지워진다.
  /// 남는 줄은 [group]줄씩 새 칸이 된다. 되돌리기 기록은 비운다.
  SyncDraft regroup(int index, int endLine, {int group = 1}) {
    if (index < 0 || index >= length) return this;
    final first = startOf(index);
    final last = endLine < first
        ? first
        : (endLine >= lines.length ? lines.length - 1 : endLine);
    var coveredIdx = index;
    var coveredEnd = first + sizes[index];
    while (coveredEnd <= last && coveredIdx + 1 < length) {
      coveredIdx++;
      coveredEnd += sizes[coveredIdx];
    }
    final rest = defaultSizes(coveredEnd - (last + 1), group);
    return SyncDraft._(
      lines,
      [
        ...sizes.take(index),
        last - first + 1,
        ...rest,
        ...sizes.skip(coveredIdx + 1),
      ],
      [
        ...times.take(index),
        null,
        ...List<Duration?>.filled(rest.length, null),
        ...times.skip(coveredIdx + 1),
      ],
      current > index ? index : current,
      const [],
    );
  }

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
      lines,
      sizes,
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

  /// 도중에 저장할 때의 LRC. 아직 안 찍은 줄도 가사가 사라지지 않게 앞 줄의 시간을 빌려 남긴다.
  String toPartialLrc() {
    var at = Duration.zero;
    return [
      for (var i = 0; i < length; i++)
        () {
          at = times[i] ?? at;
          return '${formatStamp(at)}${texts[i]}';
        }(),
    ].join('\n');
  }

  /// `01:02.30`에 대괄호를 씌운 LRC 시간 표시 (1/100초 단위).
  static String formatStamp(Duration d) {
    final cs = (d.inMilliseconds / 10).round();
    final m = cs ~/ 6000;
    final s = (cs ~/ 100) % 60;
    final f = cs % 100;
    return '[${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.${f.toString().padLeft(2, '0')}]';
  }

  static List<String> _join(List<String> lines, List<int> sizes) {
    final out = <String>[];
    var at = 0;
    for (final size in sizes) {
      out.add(lines.skip(at).take(size).join(' '));
      at += size;
    }
    return out;
  }

  static Duration _clamp(Duration d) => d < Duration.zero ? Duration.zero : d;

  SyncDraft _change({required List<Duration?> times, required int current}) =>
      SyncDraft._(lines, sizes, times, current, [
        ..._history,
        _Snapshot(this.times, this.current),
      ]);

  @override
  List<Object?> get props => [sizes, texts, times, current];
}

class _Snapshot {
  const _Snapshot(this.times, this.current);

  final List<Duration?> times;
  final int current;
}
