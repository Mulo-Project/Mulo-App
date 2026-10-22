/// 재생 속도 (1배가 보통). 고를 수 있는 값은 [options]뿐이다.
abstract final class PlaybackSpeed {
  static const normal = 1.0;

  static const options = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  /// 저장된 값이 목록에 없거나 이상하면 보통 속도로.
  static double sanitize(double? value) =>
      value != null && options.contains(value) ? value : normal;
}
