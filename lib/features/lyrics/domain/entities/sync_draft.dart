import 'package:equatable/equatable.dart';

import 'lyrics.dart';

/// 싱크 맞추기 작업 중인 가사: 줄마다 시간을 찍어 간다.
/// 원본 줄 [lines]를 [sizes]만큼씩 이어 붙인 것이 싱크 한 칸([texts])이다.
/// [current]는 다음에 시간을 찍을 칸, 끝까지 찍었으면 칸 수와 같다.
class SyncDraft extends Equatable {
  SyncDraft._(this.lines, this.sizes, this.times, this.current, this._history)
    : texts = _join(lines, sizes);

  /// [lyrics]의 빈 줄을 뺀 줄로 시작한다. 이미 싱크 가사면 그 시간을 이어받는다.
  /// 일반 글이면 [group]줄씩 하나로 묶어 한 번에 시간을 찍는다 (묶인 줄은 줄바꿈으로 이어 붙여 줄을 유지하고, 저장할 때 줄마다 같은 시간을 붙인다).
  factory SyncDraft.from(Lyrics lyrics, {int group = 1}) {
    if (lyrics.isSynced) {
      final lines = [
        for (final l in lyrics.lines)
          if (l.text.isNotEmpty) l,
      ];
      // 도중에 저장해 둔 가사는 아직 안 찍은 뒷줄이 따로 남아 있다.
      return SyncDraft._(
        [for (final l in lines) l.text, ...lyrics.pending],
        List.filled(lines.length + lyrics.pending.length, 1),
        [for (final l in lines) l.time, for (final _ in lyrics.pending) null],
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
  /// 이미 찍힌 칸이면 덮어쓰고, 그 뒤에 찍혀 있던 싱크 중 새 시간보다 이른 것은 새 시간까지 올려서
  /// 시간 순서가 뒤엉키지 않게 한다.
  SyncDraft stamp(Duration position) {
    if (current >= length) return this;
    final at = _clamp(position);
    final next = [...times]..[current] = at;
    for (var i = current + 1; i < length; i++) {
      final t = next[i];
      if (t != null && t < at) next[i] = at;
    }
    return _change(times: next, current: current + 1);
  }

  /// 가장 뒤에 찍은 싱크 하나를 지우고 그 칸이 다음에 찍을 칸이 되게 한다. 찍은 게 없으면 그대로.
  SyncDraft unstampLast() {
    final last = times.lastIndexWhere((t) => t != null);
    if (last < 0) return this;
    return _change(times: [...times]..[last] = null, current: last);
  }

  /// [index] 줄의 시간을 [delta]만큼 옮긴다. 찍지 않은 줄이면 그대로. 앞뒤로 찍힌 이웃 싱크의 시간을 넘지 않는다 (이웃은 움직이지 않는다).
  SyncDraft nudge(int index, Duration delta) {
    final t = index < 0 || index >= length ? null : times[index];
    if (t == null) return this;
    var next = _clamp(t + delta);
    // 이웃 싱크의 시간을 넘어 순서가 뒤집히지 않게 한다 (같은 시간까지는 된다). 이웃은 건드리지 않는다.
    final before = times.take(index).whereType<Duration>().lastOrNull;
    final after = times.skip(index + 1).whereType<Duration>().firstOrNull;
    if (before != null && next < before) next = before;
    if (after != null && next > after) next = after;
    return _change(times: [...times]..[index] = next, current: current);
  }

  /// 다음에 찍을 줄을 [index]로 옮긴다 (이미 찍은 시간은 그대로).
  SyncDraft moveTo(int index) => index < 0 || index > length || index == current
      ? this
      : _change(times: times, current: index);

  /// [index] 칸까지만 찍은 상태로 두고 뒤쪽은 찍지 않은 상태로 되돌린다. 다음은 [index]+1 칸.
  SyncDraft rewindTo(int index) {
    if (index < 0 || index >= length) return this;
    return _change(
      times: [for (var i = 0; i < length; i++) i <= index ? times[i] : null],
      current: index + 1,
    );
  }

  /// [index] 칸을 [group]줄씩 여러 칸으로 나눈다. 나눈 칸은 모두 이 칸의 시간을 그대로 가져서
  /// (찍은 칸이면 모두 찍힌 채로) 사이에 빈 곳이 생기지 않는다. 되돌리기 기록은 비운다.
  SyncDraft splitBlock(int index, {int group = 1}) {
    if (index < 0 || index >= length || sizes[index] < 2) return this;
    final parts = defaultSizes(sizes[index], group);
    if (parts.length < 2) return this;
    return SyncDraft._(
      lines,
      [...sizes.take(index), ...parts, ...sizes.skip(index + 1)],
      [
        ...times.take(index),
        ...List<Duration?>.filled(parts.length, times[index]),
        ...times.skip(index + 1),
      ],
      current > index ? current + parts.length - 1 : current,
      const [],
    );
  }

  /// [index] 칸의 줄을 한 줄짜리 칸으로 나눈다. 나눠도 시간은 모두 이 칸의 시간 그대로다.
  /// 되돌리기 기록은 비운다.
  SyncDraft explode(int index) {
    if (index < 0 || index >= length || sizes[index] < 2) return this;
    final n = sizes[index];
    return SyncDraft._(
      lines,
      [...sizes.take(index), ...List.filled(n, 1), ...sizes.skip(index + 1)],
      [
        ...times.take(index),
        ...List<Duration?>.filled(n, times[index]),
        ...times.skip(index + 1),
      ],
      current > index ? current + n - 1 : current,
      const [],
    );
  }

  /// [from] 칸부터 [to] 칸까지를 한 칸으로 합친다. 합친 칸은 [from] 칸의 시간을 그대로 쓰고
  /// 나머지 칸의 시간은 사라진다. 되돌리기 기록은 비운다.
  SyncDraft mergeRange(int from, int to) {
    if (from < 0 || to >= length || to <= from) return this;
    final removed = to - from;
    final next = current > to
        ? current - removed
        : (current > from ? from + 1 : current);
    return SyncDraft._(
      lines,
      [
        ...sizes.take(from),
        sizes.skip(from).take(removed + 1).fold(0, (a, b) => a + b),
        ...sizes.skip(to + 1),
      ],
      [...times.take(from + 1), ...times.skip(to + 1)],
      next,
      const [],
    );
  }

  /// [start]부터 [count]칸 안에서 이웃한 칸의 시간이 같으면 한 칸으로 다시 합친다.
  /// 돌려주는 [map]은 옛 칸 번호가 새 칸 번호로 어떻게 바뀌었는지다. 되돌리기 기록은 비운다.
  ({SyncDraft draft, List<int> map}) mergeEqual(int start, int count) {
    final newSizes = <int>[];
    final newTimes = <Duration?>[];
    final map = <int>[];
    for (var i = 0; i < length; i++) {
      final inRange = i >= start && i < start + count;
      final joins =
          inRange &&
          i > start &&
          newSizes.isNotEmpty &&
          times[i] == times[i - 1];
      if (joins) {
        newSizes[newSizes.length - 1] += sizes[i];
      } else {
        newSizes.add(sizes[i]);
        newTimes.add(times[i]);
      }
      map.add(newSizes.length - 1);
    }
    final next = current >= length ? newSizes.length : map[current];
    return (
      draft: SyncDraft._(lines, newSizes, newTimes, next, const []),
      map: map,
    );
  }

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
      if (times[i] != null) _stamped(times[i]!, texts[i]),
  ].join('\n');

  /// 도중에 저장할 때의 LRC. 마지막으로 찍은 줄까지만 시간을 붙이고, 그 뒤 줄은 시간 없는 글로 남겨
  /// 가사 화면에는 찍은 줄까지만 나오고 나중에 이어서 찍을 수 있게 한다.
  /// 중간에 건너뛴 줄은 가사가 사라지지 않게 앞 줄의 시간을 빌린다.
  String toPartialLrc() {
    final last = times.lastIndexWhere((t) => t != null);
    var at = Duration.zero;
    return [
      for (var i = 0; i < length; i++)
        if (i > last)
          texts[i]
        else
          () {
            at = times[i] ?? at;
            return _stamped(at, texts[i]);
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

  /// 한 칸의 각 줄에 같은 시간을 붙인다.
  static String _stamped(Duration at, String text) =>
      [for (final line in text.split('\n')) '${formatStamp(at)}$line']
          .join('\n');

  static List<String> _join(List<String> lines, List<int> sizes) {
    final out = <String>[];
    var at = 0;
    for (final size in sizes) {
      out.add(lines.skip(at).take(size).join('\n'));
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
