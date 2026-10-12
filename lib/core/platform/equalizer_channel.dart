import 'package:flutter/services.dart';

/// 네이티브 이퀄라이저(Android: 재생 엔진 오디오 세션의 Equalizer · BassBoost)와 주고받는 통로.
/// 약속은 docs/equalizer.md.
class EqualizerChannel {
  EqualizerChannel({MethodChannel? method})
    : _method = method ?? const MethodChannel('music_app/equalizer');

  final MethodChannel _method;

  /// 대역 주파수 · 범위 · 저음 강화 지원 여부. 쓸 수 없으면 null.
  Future<Map<Object?, Object?>?> info() =>
      _method.invokeMapMethod<Object?, Object?>('info');

  /// [levels]는 대역별 dB, [bassBoost]는 0 ~ 1.
  Future<void> apply({
    required bool enabled,
    required List<double> levels,
    required double bassBoost,
  }) => _method.invokeMethod('apply', {
    'enabled': enabled,
    'levels': levels,
    'bassBoost': bassBoost,
  });
}
