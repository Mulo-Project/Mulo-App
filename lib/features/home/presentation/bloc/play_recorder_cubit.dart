import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/home_summary.dart';
import '../../domain/usecases/home_usecases.dart';

/// 재생 기록 저장 (상세 기능: 재생 기록 저장). 상태는 마지막으로 기록한 곡 id.
///
/// 지금은 곡이 재생되기 시작할 때 한 번 기록한다. 재생 엔진이 붙으면
/// "30초 이상 들었을 때 · 들은 시간"으로 바꾼다.
class PlayRecorderCubit extends Cubit<String?> {
  PlayRecorderCubit(this._record, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(null);

  final RecordPlay _record;
  final DateTime Function() _now;

  Future<void> trackStarted(String trackId) async {
    await _record(PlayRecord(trackId: trackId, playedAt: _now()));
    if (!isClosed) emit(trackId);
  }
}
