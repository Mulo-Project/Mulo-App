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
}
