import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/playback_speed.dart';
import '../../domain/usecases/playback_speed_usecases.dart';

/// 현재 재생 속도. 바꾸면 저장하고 재생 엔진에 반영한다.
class PlaybackSpeedCubit extends Cubit<double> {
  PlaybackSpeedCubit({
    required LoadPlaybackSpeed loadSpeed,
    required SavePlaybackSpeed saveSpeed,
  }) : _load = loadSpeed,
       _save = saveSpeed,
       super(PlaybackSpeed.normal);

  final LoadPlaybackSpeed _load;
  final SavePlaybackSpeed _save;
  bool _touched = false;

  Future<void> load() async {
    final saved = await _load(const NoParams());
    if (_touched || isClosed) return;
    emit(saved);
  }

  Future<void> set(double value) async {
    _touched = true;
    emit(value);
    await _save(value);
  }
}
