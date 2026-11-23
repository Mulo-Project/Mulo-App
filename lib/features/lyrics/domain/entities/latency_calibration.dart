import 'lyrics_settings.dart';

/// 박자 테스트로 `지금`을 누를 때의 반응 시간을 구한다 (순수 계산).
class LatencyCalibration {
  const LatencyCalibration({this.intervalMs = 1000});

  /// 박자 사이 간격 (밀리초).
  final int intervalMs;

  /// 박자가 0ms에 시작해 [intervalMs]마다 울린다고 할 때, [tapMs]에 누른 것이
  /// 가장 가까운 박자보다 몇 밀리초 늦었는지 (빨랐으면 음수).
  int offsetOf(int tapMs) {
    var rest = tapMs % intervalMs;
    if (rest > intervalMs ~/ 2) rest -= intervalMs;
    return rest;
  }

  /// 누른 시간 차이들 [offsets]로 추천 보정 값(밀리초)을 구한다.
  /// 처음 [warmup]번은 박자에 익숙해지는 중이라 버리고, 나머지의 중앙값을 0 ~ 최대값 안으로 맞춘다.
  /// 쓸 값이 없으면 null.
  static int? recommend(List<int> offsets, {int warmup = 2}) {
    final used = offsets.length > warmup ? offsets.sublist(warmup) : offsets;
    if (used.isEmpty) return null;
    final sorted = [...used]..sort();
    final mid = sorted.length ~/ 2;
    final median = sorted.length.isOdd
        ? sorted[mid]
        : ((sorted[mid - 1] + sorted[mid]) / 2).round();
    return median.clamp(0, LyricsSettings.maxLatencyMs);
  }
}
