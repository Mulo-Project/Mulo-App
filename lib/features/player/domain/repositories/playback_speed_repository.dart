/// 재생 속도 설정 저장소. 음높이는 그대로 두고 빠르게 · 느리게 들려준다.
abstract interface class PlaybackSpeedRepository {
  Future<double> load();

  /// 저장하고 재생 엔진에 바로 반영한다.
  Future<void> save(double value);

  /// 저장된 값을 재생 엔진에 반영한다 (앱 시작 때).
  Future<void> apply(double value);
}
