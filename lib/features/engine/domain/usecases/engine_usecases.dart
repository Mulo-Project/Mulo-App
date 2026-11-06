import '../../../../core/usecase/usecase.dart';
import '../entities/engine_status.dart';
import '../repositories/engine_manager.dart';

/// 엔진 상태 확인.
class LoadEngineStatus implements UseCase<EngineStatus, NoParams> {
  const LoadEngineStatus(this._manager);

  final EngineManager _manager;

  @override
  Future<EngineStatus> call(NoParams params) => _manager.status();
}

/// 엔진 설치 · 업데이트 (상세 기능: yt-dlp 업데이트).
class InstallEngine implements UseCase<EngineStatus, NoParams> {
  const InstallEngine(this._manager);

  final EngineManager _manager;

  @override
  Future<EngineStatus> call(NoParams params) => _manager.install();
}
