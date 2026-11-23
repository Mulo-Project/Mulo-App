import '../../../../core/usecase/usecase.dart';
import '../entities/engine_notice.dart';
import '../entities/engine_status.dart';
import '../repositories/engine_manager.dart';
import '../repositories/engine_notices.dart';

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

/// 받기 엔진 소식 구독 (버전 때문에 받지 못했을 때 snackbar로 알린다).
class WatchEngineNotices implements StreamUseCase<EngineNotice, NoParams> {
  const WatchEngineNotices(this._notices);

  final EngineNotices _notices;

  @override
  Stream<EngineNotice> call(NoParams params) => _notices.watch();
}
