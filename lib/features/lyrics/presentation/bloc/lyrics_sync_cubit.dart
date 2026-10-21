import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lyrics.dart';
import '../../domain/entities/sync_draft.dart';

export '../../domain/entities/sync_draft.dart';

/// 싱크 맞추기 화면 상태. [selected]는 시간을 다듬고 있는 칸 (없으면 null),
/// [group]은 기본으로 한 번에 시간을 찍는 줄 수, [expanded]는 줄별로 펼쳐 둔 묶음 영역
/// (첫 칸 번호, 칸 수. 없으면 null).
class LyricsSyncState extends Equatable {
  const LyricsSyncState(
    this.draft, {
    this.selected,
    this.group = 1,
    this.expanded,
  });

  final SyncDraft draft;
  final int? selected;
  final int group;
  final (int, int)? expanded;

  @override
  List<Object?> get props => [draft, selected, group, expanded];
}

/// 줄마다 재생 위치를 찍고, 시간을 미세 조정하고, 되돌린다. 저장은 호출한 쪽이 한다.
class LyricsSyncCubit extends Cubit<LyricsSyncState> {
  LyricsSyncCubit(this._lyrics, {int group = 1})
    : super(
        LyricsSyncState(SyncDraft.from(_lyrics, group: group), group: group),
      );

  final Lyrics _lyrics;

  /// 일반 글 가사만 줄을 묶을 수 있다. 싱크 가사는 이미 시간이 있다.
  bool get canGroup => !_lyrics.isSynced;

  /// 줄을 꾹 눌러 끌어 한 칸으로 묶고 풀 수 있는가. 싱크가 있는 가사도 된다
  /// (묶으면 맨 앞 칸의 시간을 쓰고 나머지 칸의 시간은 사라진다).
  bool get canMerge => true;

  /// 기본 줄 수를 바꾸면 사라지는 작업(건너뛰어 묶은 칸 · 찍은 시간)이 있는가.
  bool get loseOnSetGroup =>
      state.draft.stamped > 0 || state.draft.isCustom(state.group);

  /// 기본 [group]줄씩 묶어 처음부터 다시 나눈다. 묶은 칸과 찍은 시간은 지워진다.
  void setGroup(int group) {
    if (!canGroup || group == state.group) return;
    emit(LyricsSyncState(SyncDraft.from(_lyrics, group: group), group: group));
  }

  /// 펼친 영역이 있으면 시간이 같은 이웃 칸을 다시 합친 모습과, 옛 칸 번호를 새 번호로 옮기는 [map].
  ({SyncDraft draft, int Function(int) map}) _collapsed() {
    final ex = state.expanded;
    if (ex == null) return (draft: state.draft, map: (i) => i);
    final r = state.draft.mergeEqual(ex.$1, ex.$2);
    return (draft: r.draft, map: (i) => i < r.map.length ? r.map[i] : i);
  }

  /// 펼친 영역을 접어 상태에 반영하고, 옛 칸 번호를 새 번호로 바꾸는 함수를 돌려준다.
  int Function(int) _collapseNow() {
    if (state.expanded == null) return (i) => i;
    final r = _collapsed();
    final sel = state.selected;
    emit(
      LyricsSyncState(
        r.draft,
        selected: sel == null ? null : r.map(sel),
        group: state.group,
      ),
    );
    return r.map;
  }

  /// 상태를 내보낸다. 포커스(선택한 칸, 없으면 다음에 찍을 칸)가 펼친 영역 밖이면 영역을 접는다.
  void _put(SyncDraft draft, {int? selected}) {
    var d = draft;
    var sel = selected;
    var ex = state.expanded;
    if (ex != null) {
      final focus = sel ?? d.current;
      if (focus < ex.$1 || focus >= ex.$1 + ex.$2) {
        final r = d.mergeEqual(ex.$1, ex.$2);
        d = r.draft;
        sel = sel == null || sel >= r.map.length ? sel : r.map[sel];
        ex = null;
      }
    }
    emit(LyricsSyncState(d, selected: sel, group: state.group, expanded: ex));
  }

  /// 묶인 [index] 칸을 줄별로 펼친다. 줄마다 시간을 따로 정할 수 있고, 영역 밖으로 포커스가 나가면
  /// 시간이 같은 줄은 다시 합쳐진다.
  void expand(int index) {
    if (!canMerge || index < 0 || index >= state.draft.length) return;
    final r = _collapsed();
    final target = r.map(index);
    if (target >= r.draft.length || r.draft.sizes[target] < 2) return;
    final n = r.draft.sizes[target];
    emit(
      LyricsSyncState(
        r.draft.explode(target).moveTo(target),
        selected: target,
        group: state.group,
        expanded: (target, n),
      ),
    );
  }

  /// [index] 칸이 기본 줄 수보다 많이 묶여 있는가 (건너뛰어 같은 시간으로 묶인 칸).
  bool isMerged(int index) =>
      index >= 0 &&
      index < state.draft.length &&
      state.draft.sizes[index] > state.group;

  /// 묶인 [index] 칸을 기본 줄 수로 다시 나눈다. 나눈 칸은 이 칸의 시간을 그대로 가져서
  /// (찍은 칸이면 모두 찍힌 채로) 공백이 생기지 않고, 이어서 줄마다 시간을 다듬으면 된다.
  void split(int index) {
    if (!canMerge || !isMerged(index)) return;
    final at = _collapseNow()(index);
    final draft = state.draft;
    if (at >= draft.length || draft.sizes[at] <= state.group) return;
    emit(
      LyricsSyncState(
        draft.splitBlock(at, group: state.group).moveTo(at),
        selected: at,
        group: state.group,
      ),
    );
  }

  /// 포커스한 칸 바로 다음 칸의 이미 찍어 둔 시간 (자동 멈춤이 멈출 곳). 없으면 null.
  Duration? get nextStampAfterFocus {
    final at = state.selected;
    final draft = state.draft;
    if (at == null || at + 1 >= draft.length) return null;
    return draft.times[at + 1];
  }

  /// [from]~[to] 칸을 한 칸으로 묶는다 (끌어서 고른 범위). [from] 칸의 시간을 쓰고, 나머지 칸의
  /// 싱크는 사라진다.
  void mergeRange(int from, int to) {
    if (!canMerge) return;
    final map = _collapseNow();
    final a = map(from), b = map(to);
    final draft = state.draft;
    if (a < 0 || b >= draft.length || b <= a) return;
    emit(
      LyricsSyncState(
        draft.mergeRange(a, b).moveTo(a),
        selected: a,
        group: state.group,
      ),
    );
  }

  /// [from]~[to] 칸을 묶으면 [from] 다음 칸들의 이미 찍어 둔 싱크가 사라지는가.
  bool rangeErasesStamped(int from, int to) {
    final draft = state.draft;
    if (from < 0 || to >= draft.length) return false;
    for (var i = from + 1; i <= to; i++) {
      if (draft.times[i] != null) return true;
    }
    return false;
  }

  /// [position]을 포커스한 칸(찍을 차례인 칸)에 찍는다. 이미 찍힌 칸이면 덮어쓰고 이웃 싱크는 순서가 유지되게
  /// 함께 맞춘다. 찍으면 포커스가 다음 칸으로 넘어간다.
  void stamp(Duration position) {
    var draft = state.draft;
    var at = draft.current;
    if (at >= draft.length) return;
    // 찍은 칸이 이웃 칸과 같은 시간이 되면 그 칸들을 바로 한 묶음으로 보인다 (저장하고 다시 열 때와 같게).
    // 첫 싱크를 가운데 줄에서 시작했다면, 맨 앞 줄부터 그 줄까지를 한 칸으로 묶어 같은 시간으로 찍는다.
    if (canGroup && draft.stamped == 0 && at > 0 && state.expanded == null) {
      draft = draft.mergeRange(0, at).moveTo(0);
      at = 0;
    }
    var stamped = draft.stamp(position);
    // 앞쪽으로 당겨 찍어 그 앞의 싱크가 함께 내려왔다면, 바뀐 것 중 맨 앞 칸으로 포커스를 돌려 확인하게 한다.
    var focus = at + 1 < stamped.length ? at + 1 : at;
    var redirected = false;
    for (var i = 0; i < at; i++) {
      if (stamped.times[i] != draft.times[i]) {
        stamped = stamped.moveTo(i);
        focus = i;
        redirected = true;
        break;
      }
    }
    // 펼쳐서 줄별로 다듬는 중이거나 앞 싱크가 함께 내려온 경우가 아니면, 같은 시간의 이웃 칸을 묶는다.
    // 한 번 찍을 때 앞 또는 뒤 한 칸(홑줄)만 묶는다. 이미 묶인 칸은 삼키지 않아 묶음이 제한 없이 뻗지 않고,
    // 묶음을 더 키우려면 그 묶음을 다시 골라 찍는다.
    if (!redirected && state.expanded == null) {
      var idx = at;
      final t = stamped.times;
      final s = stamped.sizes;
      if (t[idx] != null) {
        if (idx > 0 && t[idx] == t[idx - 1] && s[idx - 1] == 1) {
          stamped = stamped.mergeRange(idx - 1, idx);
          idx -= 1;
        } else if (idx + 1 < stamped.length &&
            t[idx] == t[idx + 1] &&
            s[idx + 1] == 1) {
          stamped = stamped.mergeRange(idx, idx + 1);
        }
      }
      focus = idx + 1 < stamped.length ? idx + 1 : idx;
    }
    // 그렇지 않으면 찍은 뒤 포커스가 자동으로 다음 칸으로 넘어간다 (지금은 포커스한 칸만 바꾼다).
    _put(stamped, selected: focus);
  }

  /// 줄을 눌렀을 때: 찍은 줄은 포커스하고 그 칸을 다시 찍을 차례로 옮긴다 (싱크 값은 바뀌지 않는다).
  /// 아직 안 찍은 줄이면 거기부터 찍도록 옮기기만 한다 (묶기는 꾹 눌러 끌어서 따로 한다).
  void select(int index) {
    if (index < 0 || index >= state.draft.length) return;
    final ex = state.expanded;
    // 펼친 영역 밖을 누르면 영역을 먼저 접고, 접힌 뒤의 칸 번호로 이어서 처리한다.
    if (ex != null && (index < ex.$1 || index >= ex.$1 + ex.$2)) {
      select(_collapseNow()(index));
      return;
    }
    final draft = state.draft;
    if (draft.times[index] != null) {
      // 찍은 줄을 누르면 포커스하고, 그 칸이 다시 찍을 차례가 된다 (싱크 값은 바뀌지 않는다.
      // 재생은 화면에서 그 싱크로 옮긴다). 값이 바뀌는 건 지금 버튼을 눌렀을 때뿐이다.
      emit(
        LyricsSyncState(
          draft.moveTo(index),
          selected: index,
          group: state.group,
          expanded: ex,
        ),
      );
      return;
    }
    // 싱크가 하나라도 등록된 뒤에는 안 찍은 칸 중 맨 앞 칸(이어 찍을 자리)으로만 돌아갈 수 있다.
    // 아직 하나도 안 찍었을 때만 원하는 줄에서 시작하도록 아무 칸이나 고를 수 있다.
    if (draft.stamped > 0 && index != draft.times.indexOf(null)) return;
    emit(
      LyricsSyncState(
        draft.moveTo(index),
        selected: index,
        group: state.group,
        expanded: ex,
      ),
    );
  }

  /// 가장 뒤에 찍은 싱크를 하나 지우고 그 칸으로 돌아간다 (다시 찍으려는 뒤로 가기). 되돌리기로 복구된다.
  void stepBack() {
    final draft = state.draft;
    // 묶인 칸이 마지막이면 수정 중이므로 묶음을 풀고(줄마다 그 시간 그대로) 맨 끝 줄만 비운다.
    final last = draft.times.lastIndexWhere((t) => t != null);
    if (last >= 0 && draft.sizes[last] > 1 && canMerge) {
      final map = _collapseNow();
      final at = map(last);
      final d = state.draft;
      final n = d.sizes[at];
      final next = d.explode(at).unstampLast();
      emit(
        LyricsSyncState(
          next,
          selected: next.current,
          group: state.group,
          expanded: (at, n),
        ),
      );
      return;
    }
    final next = draft.unstampLast();
    if (next == draft) return;
    _put(next, selected: next.current);
  }

  /// 선택한 줄의 시간을 [delta]만큼 옮긴다.
  void nudge(Duration delta) {
    final at = state.selected;
    if (at == null) return;
    _put(state.draft.nudge(at, delta), selected: at);
  }

  /// [index] 줄의 싱크만 남기고 뒤쪽은 등록을 풀어, 다음 줄부터 다시 찍게 한다.
  void rewindTo(int index) {
    final draft = state.draft.rewindTo(index);
    if (draft == state.draft) return;
    _put(draft, selected: index + 1 < draft.length ? index + 1 : index);
  }

  void undo() {
    if (!state.draft.canUndo) return;
    final draft = state.draft.undo();
    _put(
      draft,
      selected: draft.current < draft.length
          ? draft.current
          : _lastStamped(draft),
    );
  }

  /// 되돌린 뒤에 선택할 줄: 바로 앞에 찍은 줄.
  static int? _lastStamped(SyncDraft draft) {
    final i = draft.current - 1;
    return i >= 0 && draft.times[i] != null ? i : null;
  }
}
