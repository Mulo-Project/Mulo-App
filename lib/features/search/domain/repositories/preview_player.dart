import '../entities/audio_stream.dart';
import '../entities/preview_progress.dart';

/// 미리 듣기 전용 플레이어. 메인 재생(대기열 · 미니 플레이어)과는 따로 움직이며 한 번에 한 곡만 낸다.
///
/// 불러오지 못하면 [EngineException]으로 던진다.
abstract interface class PreviewPlayer {
  /// [stream]을 불러와 재생을 시작한다. 이미 재생 중이면 바꿔 끼운다.
  Future<void> play(AudioStream stream);

  /// 재생을 멈추고 놓는다.
  Future<void> stop();

  /// 끝까지 재생했을 때마다 한 번씩.
  Stream<void> watchCompleted();

  /// 재생 위치가 바뀔 때마다 (재생 중에만).
  Stream<PreviewProgress> watchProgress();
}
