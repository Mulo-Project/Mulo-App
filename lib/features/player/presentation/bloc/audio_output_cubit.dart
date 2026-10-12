import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/audio_output.dart';
import '../../domain/usecases/get_audio_output.dart';

export '../../domain/entities/audio_output.dart';

/// 지금 출력 기기 (미니 플레이어에 작게 보인다). 알 수 없으면 null.
/// 블루투스 연결 · 끊김, 이어폰 꽂기 · 빼기로 기기가 바뀌면 스스로 다시 읽는다.
class AudioOutputCubit extends Cubit<AudioOutput?> {
  AudioOutputCubit(this._get, [this._watch]) : super(null);

  final GetAudioOutput _get;
  final WatchAudioOutputChanges? _watch;
  StreamSubscription<void>? _changes;

  Future<void> refresh() async {
    final out = await _get(const NoParams());
    if (!isClosed) emit(out);
  }

  /// 출력 기기가 바뀔 때 다시 읽기 시작한다.
  Future<void> watch() async {
    final watch = _watch;
    if (watch == null || _changes != null) return;
    final stream = await watch(const NoParams());
    if (isClosed) return;
    _changes = stream.listen((_) => refresh());
  }

  @override
  Future<void> close() {
    _changes?.cancel();
    return super.close();
  }
}
