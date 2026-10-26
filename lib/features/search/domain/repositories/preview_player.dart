import '../entities/audio_stream.dart';
import '../entities/media_info.dart';
import '../entities/preview_progress.dart';
import '../entities/preview_snapshot.dart';

/// 미리 듣기 전용 플레이어. 메인 재생(대기열 · 미니 플레이어)과는 따로 움직이며 한 번에 한 곡만 낸다.
///
/// 불러오지 못하면 [EngineException]으로 던진다.
abstract interface class PreviewPlayer {
  /// [stream]을 불러와 재생을 시작한다. 이미 재생 중이면 바꿔 끼운다.
  Future<void> play(AudioStream stream);

  /// 재생 위치를 [position]으로 옮긴다 (재생 중이 아니면 아무 일도 없다).
  Future<void> seek(Duration position);

  /// 소리를 잠시 멈춘다 (자리는 그대로).
  Future<void> pause();

  /// 잠시 멈춘 자리에서 다시 재생한다.
  Future<void> resume();

  /// 재생을 멈추고 놓는다.
  Future<void> stop();

  /// 지금 재생 중인 미리 듣기가 어느 곡인지 플레이어에 적어 둔다 (앱이 꺼졌다 켜져도 되살리려고).
  Future<void> remember(MediaHit hit);

  /// 플레이어가 지금 내고 있는 미리 듣기. 소리를 내는 게 없으면 null.
  Future<PreviewSnapshot?> current();

  /// 끝까지 재생했을 때마다 한 번씩.
  Stream<void> watchCompleted();

  /// 재생이 시작된 뒤에 소리가 끊기는 오류(주소가 중간에 막힘 등)가 났을 때 그 까닭.
  Stream<String> watchFailures();

  /// 재생 위치가 바뀔 때마다 (재생 중에만).
  Stream<PreviewProgress> watchProgress();
}
