import '../entities/output_behavior.dart';

/// 출력 기기 동작 설정 저장소. 로직(멈춤 · 이어 재생)은 네이티브가 처리하고 앱은 값만 저장해 전한다.
abstract interface class OutputBehaviorRepository {
  Future<OutputBehavior> load();

  /// 저장하고 재생 엔진에 바로 반영한다.
  Future<void> save(OutputBehavior value);

  /// 저장된 값을 재생 엔진에 반영한다 (앱 시작 때).
  Future<void> apply(OutputBehavior value);
}
