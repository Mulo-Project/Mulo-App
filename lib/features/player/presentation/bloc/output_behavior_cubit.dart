import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/output_behavior.dart';
import '../../domain/usecases/output_behavior_usecases.dart';

export '../../domain/entities/output_behavior.dart';

/// 출력 기기 동작 설정 (끊기면 일시정지 · 연결되면 이어 재생). 바꾸면 저장하고 재생 엔진에 반영한다.
class OutputBehaviorCubit extends Cubit<OutputBehavior> {
  OutputBehaviorCubit({
    required LoadOutputBehavior loadBehavior,
    required SaveOutputBehavior saveBehavior,
    bool? supported,
  }) : _load = loadBehavior,
       _save = saveBehavior,
       supported = supported ?? Platform.isAndroid,
       super(const OutputBehavior());

  final LoadOutputBehavior _load;
  final SaveOutputBehavior _save;

  /// 이 기능을 쓸 수 있는 환경인지 (Android). 아니면 설정 줄을 숨긴다.
  final bool supported;
  bool _touched = false;

  Future<void> load() async {
    final saved = await _load(const NoParams());
    if (_touched || isClosed) return;
    emit(saved);
  }

  Future<void> setPauseOnDisconnect(bool value) =>
      _set(state.copyWith(pauseOnDisconnect: value));

  Future<void> setResumeOnConnect(bool value) =>
      _set(state.copyWith(resumeOnConnect: value));

  Future<void> _set(OutputBehavior value) async {
    _touched = true;
    emit(value);
    await _save(value);
  }
}
