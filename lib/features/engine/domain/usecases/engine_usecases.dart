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

/// 앱이 받아 둔 엔진(yt-dlp) 지우기.
class RemoveEngine implements UseCase<EngineStatus, NoParams> {
  const RemoveEngine(this._manager);

  final EngineManager _manager;

  @override
  Future<EngineStatus> call(NoParams params) => _manager.remove();
}

/// 업데이트한 엔진(yt-dlp)을 앱에 들어 있는 버전으로 되돌리기.
class RevertEngine implements UseCase<EngineStatus, NoParams> {
  const RevertEngine(this._manager);

  final EngineManager _manager;

  @override
  Future<EngineStatus> call(NoParams params) => _manager.revertToBundled();
}
