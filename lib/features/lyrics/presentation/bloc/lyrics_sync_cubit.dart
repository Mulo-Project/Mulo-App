import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lyrics.dart';
import '../../domain/entities/sync_draft.dart';

export '../../domain/entities/sync_draft.dart';

/// 싱크 맞추기 화면 상태. [selected]는 시간을 다듬고 있는 칸 (없으면 null),
/// [group]은 기본으로 한 번에 시간을 찍는 줄 수, [editing]은 줄을 다시 묶고 있는 칸 (없으면 null).
class LyricsSyncState extends Equatable {
  const LyricsSyncState(
    this.draft, {
    this.selected,
    this.group = 1,
    this.editing,
  });

  final SyncDraft draft;
  final int? selected;
  final int group;
  final int? editing;

  @override
  List<Object?> get props => [draft, selected, group, editing];
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

  /// 기본 줄 수를 바꾸면 사라지는 작업(직접 묶음 · 찍은 시간)이 있는가.
  bool get loseOnSetGroup =>
      state.draft.stamped > 0 || state.draft.isCustom(state.group);

  /// 기본 [group]줄씩 묶어 처음부터 다시 나눈다. 직접 묶은 줄과 찍은 시간은 지워진다.
  void setGroup(int group) {
    if (!canGroup || group == state.group) return;
    emit(LyricsSyncState(SyncDraft.from(_lyrics, group: group), group: group));
  }

  /// [index] 칸의 줄 묶기를 시작한다.
  void startGroupEdit(int index) {
    if (!canGroup || index < 0 || index >= state.draft.length) return;
    emit(
      LyricsSyncState(
        state.draft,
        selected: index,
        group: state.group,
        editing: index,
      ),
    );
  }

  void endGroupEdit() {
    emit(
      LyricsSyncState(
        state.draft,
        selected: state.selected,
        group: state.group,
      ),
    );
  }

  /// 줄 묶는 중인 칸을 원본 [endLine] 줄까지로 다시 묶는다.
  void regroup(int endLine) {
    final at = state.editing;
    if (at == null) return;
    final draft = state.draft.regroup(at, endLine, group: state.group);
    if (draft == state.draft) return;
    emit(LyricsSyncState(draft, selected: at, group: state.group, editing: at));
  }

  /// [position]을 다음 줄에 찍는다. 찍은 줄이 선택돼 바로 다듬을 수 있다.
  void stamp(Duration position) {
    final at = state.draft.current;
    if (at >= state.draft.length) return;
    emit(
      LyricsSyncState(
        state.draft.stamp(position),
        selected: at,
        group: state.group,
      ),
    );
  }

  /// 줄을 눌렀을 때: 찍은 줄은 선택하고, 아직 안 찍은 줄은 거기부터 찍도록 옮긴다.
  void select(int index) {
    final draft = state.draft;
    if (index < 0 || index >= draft.length) return;
    if (draft.times[index] != null) {
      emit(LyricsSyncState(draft, selected: index, group: state.group));
    } else {
      emit(LyricsSyncState(draft.moveTo(index), group: state.group));
    }
  }

  /// 선택한 줄의 시간을 [delta]만큼 옮긴다.
  void nudge(Duration delta) {
    final at = state.selected;
    if (at == null) return;
    emit(
      LyricsSyncState(
        state.draft.nudge(at, delta),
        selected: at,
        group: state.group,
      ),
    );
  }

  /// [index] 줄의 싱크만 남기고 뒤쪽은 등록을 풀어, 다음 줄부터 다시 찍게 한다.
  void rewindTo(int index) {
    final draft = state.draft.rewindTo(index);
    if (draft == state.draft) return;
    emit(LyricsSyncState(draft, selected: index, group: state.group));
  }

  void undo() {
    if (!state.draft.canUndo) return;
    final draft = state.draft.undo();
    emit(
      LyricsSyncState(draft, selected: _lastStamped(draft), group: state.group),
    );
  }

  /// 되돌린 뒤에 선택할 줄: 바로 앞에 찍은 줄.
  static int? _lastStamped(SyncDraft draft) {
    final i = draft.current - 1;
    return i >= 0 && draft.times[i] != null ? i : null;
  }
}
