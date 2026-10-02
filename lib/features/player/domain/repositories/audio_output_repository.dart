import '../entities/audio_output.dart';

abstract interface class AudioOutputRepository {
  /// 지금 소리가 나가는 기기. 알 수 없으면 null.
  Future<AudioOutput?> current();
}
