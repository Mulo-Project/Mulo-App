import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/stop_log_usecases.dart';

/// 재생 중단 기록 시트. 상태는 기록 줄(최신이 앞). 불러오기 전에는 null.
class StopLogCubit extends Cubit<List<String>?> {
  StopLogCubit({
    required GetStopLog getLog,
    required ClearStopLog clearLog,
    bool? supported,
  }) : _get = getLog,
       _clear = clearLog,
       supported = supported ?? Platform.isAndroid,
       super(null);

  final GetStopLog _get;
  final ClearStopLog _clear;

  /// 기록을 남기는 환경인지 (Android). 아니면 설정 줄을 숨긴다.
  final bool supported;

  Future<void> load() async {
    final lines = await _get(const NoParams());
    if (!isClosed) emit(lines.reversed.toList());
  }

  Future<void> clear() async {
    await _clear(const NoParams());
    if (!isClosed) emit(const []);
  }
}
