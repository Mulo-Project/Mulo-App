/// 오디오 재생 엔진 (한 번에 한 곡).
abstract interface class AudioPlayerRepository {
  /// 재생 위치. 재생 중에만 계속 흘러나온다.
  Stream<Duration> watchPosition();

  /// 곡 끝까지 재생했을 때마다 한 번씩.
  Stream<void> watchCompleted();

  /// 엔진이 실제로 소리를 내려는 상태가 바뀔 때마다. 앱이 시킨 재생 · 정지뿐 아니라
  /// 다른 앱에 오디오 포커스를 뺏겨 멈추거나 돌려받아 다시 시작할 때도 알려 준다.
  Stream<bool> watchPlaying();

  /// [uri]의 곡을 불러온다 (재생은 [play]로 시작). 못 불러오면 던진다.
  Future<void> load(String uri);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);
}
