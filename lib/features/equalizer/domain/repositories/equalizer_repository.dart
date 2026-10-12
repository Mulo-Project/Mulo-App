import '../entities/equalizer_settings.dart';

/// 이퀄라이저 값 저장소 + 재생 엔진 반영. 효과는 플랫폼 네이티브가 낸다.
/// 출력 기기(블루투스 이어폰 · 스피커 등)마다 전용 값을 둘 수 있고, 기기가 바뀌면 네이티브가 알아서 바꿔 적용한다.
abstract interface class EqualizerRepository {
  /// 기기 능력과 값. 값은 지금 출력 기기 전용 값이 있으면 그 값, 없으면 기본 저장 값.
  /// 이퀄라이저를 못 쓰는 환경이면 `info`가 null.
  Future<EqualizerSetup> load();

  /// 값을 재생 엔진에 바로 반영한다 (저장하지 않는다).
  Future<void> apply(EqualizerSettings settings);

  /// 값을 저장한다. 지금 출력 기기 전용 값이 있으면 그쪽에, 없으면 기본 저장 값에 저장한다.
  Future<void> save(EqualizerSettings settings);

  /// 지금 출력 기기 전용 값을 만들거나([enabled] true, [settings]를 저장) 지운다 (기본 저장 값을 다시 쓴다).
  Future<void> setDeviceProfile(bool enabled, EqualizerSettings settings);

  /// 출력 기기가 바뀔 때마다 알려 준다 (네이티브가 새 기기의 값을 이미 적용했다).
  Stream<void> watchDevice();

  /// 만들어 둔 내 프리셋 (만든 순서).
  Future<List<EqualizerUserPreset>> presets();

  /// 내 프리셋을 만들거나 고친다. 이 프리셋을 지정한 기기의 값도 함께 바뀐다.
  Future<void> savePreset(EqualizerUserPreset preset);

  /// 내 프리셋을 지운다 (지정했던 기기는 마지막 값을 그대로 쓴다).
  Future<void> deletePreset(String id);

  /// 연결된 적 있는 출력 기기 (지금 기기가 맨 위).
  Future<List<EqualizerDevice>> devices();

  /// [deviceKey] 기기에 내 프리셋을 지정한다. [presetId]가 null이면 전용 값을 없앤다.
  Future<void> assignPreset(String deviceKey, String? presetId);
}
