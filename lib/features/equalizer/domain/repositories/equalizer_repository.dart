import '../entities/equalizer_settings.dart';

/// 이퀄라이저 값 저장소 + 재생 엔진 반영. 효과는 플랫폼 네이티브가 낸다.
abstract interface class EqualizerRepository {
  /// 기기 능력과 저장된 값. 이퀄라이저를 못 쓰는 환경이면 `info`가 null.
  Future<EqualizerSetup> load();

  /// 값을 재생 엔진에 바로 반영한다 (저장하지 않는다).
  Future<void> apply(EqualizerSettings settings);

  /// 값을 저장한다.
  Future<void> save(EqualizerSettings settings);
}
