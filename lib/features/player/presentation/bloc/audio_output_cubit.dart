import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/audio_output.dart';
import '../../domain/usecases/get_audio_output.dart';

export '../../domain/entities/audio_output.dart';

/// 지금 출력 기기 (미니 플레이어에 작게 보인다). 알 수 없으면 null.
class AudioOutputCubit extends Cubit<AudioOutput?> {
  AudioOutputCubit(this._get) : super(null);

  final GetAudioOutput _get;

  Future<void> refresh() async {
    final out = await _get(const NoParams());
    if (!isClosed) emit(out);
  }
}
