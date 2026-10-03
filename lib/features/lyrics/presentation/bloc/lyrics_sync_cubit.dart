import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lyrics.dart';
import '../../domain/entities/sync_draft.dart';

export '../../domain/entities/sync_draft.dart';

/// 싱크 맞추기 화면 상태. [selected]는 시간을 다듬고 있는 줄 (없으면 null),
/// [group]은 한 번에 시간을 찍는 줄 수.
class LyricsSyncState extends Equatable {
  const LyricsSyncState(this.draft, {this.selected, this.group = 1});

  final SyncDraft draft;
  final int? selected;
  final int group;

  @override
  List<Object?> get props => [draft, selected, group];
}

/// 줄마다 재생 위치를 찍고, 시간을 미세 조정하고, 되돌린다. 저장은 호출한 쪽이 한다.
class LyricsSyncCubit extends Cubit<LyricsSyncState> {
  LyricsSyncCubit(this._lyrics, {int group = 1})
    : super(
        LyricsSyncState(SyncDraft.from(_lyrics, group: group), group: group),
      );

  final Lyrics _lyrics;

  /// 일반 글 가사의 묶음 줄 수. 싱크 가사는 이미 시간이 있어 묶을 수 없다.
  bool get canGroup => !_lyrics.isSynced;

  /// 아직 아무 줄도 찍지 않았을 때만 [group]줄씩 묶어 다시 나눈다.
  void setGroup(int group) {
    if (!canGroup || state.draft.stamped > 0 || group == state.group) return;
    emit(LyricsSyncState(SyncDraft.from(_lyrics, group: group), group: group));
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
