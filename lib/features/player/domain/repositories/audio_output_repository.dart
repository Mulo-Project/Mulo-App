import '../entities/audio_output.dart';

abstract interface class AudioOutputRepository {
  /// 지금 소리가 나가는 기기. 알 수 없으면 null.
  Future<AudioOutput?> current();

  /// 출력 기기가 연결되거나 끊길 때마다 알려 준다.
  Stream<void> watchChanges();
}
