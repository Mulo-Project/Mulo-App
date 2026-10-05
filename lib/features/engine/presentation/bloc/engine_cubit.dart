import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/engine_status.dart';
import '../../domain/usecases/engine_usecases.dart';

class EngineState extends Equatable {
  const EngineState({this.status, this.busy = false, this.failed = false});

  /// 아직 확인 전이면 null.
  final EngineStatus? status;

  /// 설치 · 업데이트 중.
  final bool busy;
  final bool failed;

  @override
  List<Object?> get props => [status, busy, failed];
}

/// 설정의 엔진 줄: 상태 확인과 설치 · 업데이트.
class EngineCubit extends Cubit<EngineState> {
  EngineCubit(this._load, this._install) : super(const EngineState());

  final LoadEngineStatus _load;
  final InstallEngine _install;

  Future<void> load() async {
    final status = await _load(const NoParams());
    if (!isClosed) emit(EngineState(status: status));
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
