import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/engine_status.dart';
import '../../domain/usecases/engine_usecases.dart';

class EngineState extends Equatable {
  const EngineState({
    this.status,
    this.busy = false,
    this.failed = false,
    this.reverting = false,
  });

  /// 아직 확인 전이면 null.
  final EngineStatus? status;

  /// 설치 · 업데이트 중.
  final bool busy;
  final bool failed;

  /// 진행 중이거나 실패한 작업이 "번들 버전으로 되돌리기"인지 (아니면 설치 · 업데이트).
  final bool reverting;

  @override
  List<Object?> get props => [status, busy, failed, reverting];
}

/// 설정의 엔진 줄: 상태 확인과 설치 · 업데이트.
class EngineCubit extends Cubit<EngineState> {
  EngineCubit(this._load, this._install, this._remove, this._revert)
    : super(const EngineState());

  final LoadEngineStatus _load;
  final InstallEngine _install;
  final RemoveEngine _remove;
  final RevertEngine _revert;

  Future<void> load() async {
    final status = await _load(const NoParams());
    if (!isClosed) emit(EngineState(status: status));
  }

  /// 앱이 받아 둔 엔진을 지운다 (지울 수 없는 상태면 아무것도 하지 않는다).
  Future<void> remove() async {
    if (state.busy || state.status?.removable != true) return;
    emit(EngineState(status: state.status, busy: true));
    try {
      final status = await _remove(const NoParams());
      if (!isClosed) emit(EngineState(status: status));
    } on Object {
      if (!isClosed) emit(EngineState(status: state.status, failed: true));
    }
  }

  /// 업데이트한 엔진을 앱에 들어 있는 버전으로 되돌린다 (되돌릴 수 없는 상태면 아무것도 하지 않는다).
  Future<void> revert() async {
    if (state.busy || state.status?.revertible != true) return;
    emit(EngineState(status: state.status, busy: true, reverting: true));
    try {
      final status = await _revert(const NoParams());
      if (!isClosed) emit(EngineState(status: status));
    } on Object {
      if (!isClosed) {
        emit(EngineState(status: state.status, failed: true, reverting: true));
      }
    }
  }

  Future<void> install() async {
    if (state.busy) return;
    emit(EngineState(status: state.status, busy: true));
    try {
      final status = await _install(const NoParams());
      if (!isClosed) emit(EngineState(status: status));
    } on Object {
      if (!isClosed) emit(EngineState(status: state.status, failed: true));
    }
  }
}
