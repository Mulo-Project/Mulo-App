import '../entities/playback_snapshot.dart';

/// 오디오 재생 엔진. 앱이 보내 준 대기열 스냅샷을 순서대로 재생하고 곡 넘김은 엔진이 한다.
abstract interface class AudioPlayerRepository {
  /// 재생 위치. 재생 중에만 계속 흘러나온다.
  Stream<Duration> watchPosition();

  /// 엔진이 스스로 다른 곡으로 넘어갔을 때 (곡 끝, 알림 · 이어폰의 이전 · 다음).
  /// 앱이 시킨 이동([setQueue] · [skipTo])에는 보내지 않는다.
  Stream<PlaybackTrackChange> watchTrackChange();

  /// 반복 없이 대기열 끝까지 재생했을 때.
  Stream<void> watchEnded();

  /// 엔진이 실제로 소리를 내려는 상태가 바뀔 때마다. 앱이 시킨 재생 · 정지뿐 아니라
  /// 다른 앱에 오디오 포커스를 뺏겨 멈추거나 돌려받아 다시 시작할 때도 알려 준다.
  Stream<bool> watchPlaying();

  /// 앱이 켜져 있는 중에 알림을 눌러 플레이어 화면을 열라는 요청.
  Stream<void> watchOpenPlayer();

  /// 대기열을 통째로 바꾼다. 현재 곡이 같으면 재생을 끊지 않는다.
  /// 현재 곡을 못 불러오면 던진다.
  Future<void> setQueue(PlaybackSnapshot snapshot);

  /// 대기열은 그대로 두고 [index]번 곡으로 처음부터 옮긴다.
  Future<void> skipTo(int index);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  /// 엔진이 지금 쥐고 있는 대기열 (앱을 다시 켰을 때 복원용). 없으면 null.
  Future<PlaybackSnapshot?> restore();

  /// 알림을 눌러 앱이 새로 켜졌는지 한 번 알려 주고 비운다.
  Future<bool> takeOpenPlayerRequest();
}
