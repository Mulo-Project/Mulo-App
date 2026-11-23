import 'dart:async';

import 'package:flutter/services.dart';

/// 네이티브 이퀄라이저(Android: 재생 엔진 오디오 세션의 Equalizer · BassBoost)와 주고받는 통로.
/// 약속은 docs/equalizer.md.
class EqualizerChannel {
  EqualizerChannel({MethodChannel? method})
    : _method = method ?? const MethodChannel('music_app/equalizer');

  final MethodChannel _method;
  StreamController<void>? _deviceChanges;

  /// 대역 주파수 · 범위 · 저음 강화 지원 여부. 쓸 수 없으면 null.
  Future<Map<Object?, Object?>?> info() =>
      _method.invokeMapMethod<Object?, Object?>('info');

  /// [levels]는 대역별 dB, [bassBoost] · [virtualizer]는 0 ~ 1, [reverb]는 PresetReverb 번호(0 = 없음),
  /// [limiter]는 클리핑 방지.
  Future<void> apply({
    required bool enabled,
    required List<double> levels,
    required double bassBoost,
    required double virtualizer,
    required int reverb,
    required bool limiter,
  }) => _method.invokeMethod('apply', {
    'enabled': enabled,
    'levels': levels,
    'bassBoost': bassBoost,
    'virtualizer': virtualizer,
    'reverb': reverb,
    'limiter': limiter,
  });

  /// 지금 출력 기기 `{key, type, name, hasProfile}`.
  Future<Map<Object?, Object?>?> device() =>
      _method.invokeMapMethod<Object?, Object?>('device');

  /// 지금 출력 기기 전용 값 (없으면 null). 모양은 [saveProfile]에 보낸 맵과 같다.
  Future<Map<Object?, Object?>?> profile() =>
      _method.invokeMapMethod<Object?, Object?>('profile');

  /// 지금 출력 기기 전용 값을 저장한다 (이후 이 기기가 연결되면 네이티브가 자동으로 적용한다).
  Future<void> saveProfile(Map<String, Object?> values) =>
      _method.invokeMethod('saveProfile', values);

  Future<void> deleteProfile() => _method.invokeMethod('deleteProfile');

  /// 전용 값이 없는 기기에 쓸 기본 값을 네이티브에 알려 둔다 (앱이 꺼져도 적용되게).
  Future<void> setBase(Map<String, Object?> values) =>
      _method.invokeMethod('setBase', values);

  /// [key] 기기의 전용 값 (없으면 null).
  Future<Map<Object?, Object?>?> profileFor(String key) =>
      _method.invokeMapMethod<Object?, Object?>('profileFor', key);

  /// [key] 기기의 전용 값을 저장한다 (지금 기기가 아니어도).
  Future<void> saveProfileFor(String key, Map<String, Object?> values) =>
      _method.invokeMethod('saveProfileFor', {'key': key, 'values': values});

  /// 이름을 붙여 만들어 둔 내 프리셋 (`id` `name` + `apply` 인자와 같은 값).
  Future<List<Object?>?> presets() =>
      _method.invokeListMethod<Object?>('presets');

  Future<void> savePreset(Map<String, Object?> preset) =>
      _method.invokeMethod('savePreset', preset);

  Future<void> deletePreset(String id) =>
      _method.invokeMethod('deletePreset', id);

  /// 연결된 적 있는 출력 기기 `{key, type, name, hasProfile, presetId, current}`.
  Future<List<Object?>?> devices() =>
      _method.invokeListMethod<Object?>('devices');

  /// [key] 기기에 내 프리셋을 지정한다 ([presetId]가 null이면 전용 값을 없앤다).
  Future<void> assignPreset(String key, String? presetId) =>
      _method.invokeMethod('assignPreset', {'key': key, 'presetId': presetId});

  /// 출력 기기가 바뀌어 네이티브가 새 값을 적용했을 때 알려 준다.
  Stream<void> get deviceChanges {
    return (_deviceChanges ??= StreamController<void>.broadcast(
      onListen: () => _method.setMethodCallHandler((call) async {
        if (call.method == 'deviceChanged') _deviceChanges?.add(null);
      }),
    )).stream;
  }
}
