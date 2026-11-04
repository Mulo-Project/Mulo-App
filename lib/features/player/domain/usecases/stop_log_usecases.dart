import '../../../../core/usecase/usecase.dart';
import '../repositories/stop_log_repository.dart';

class GetStopLog implements UseCase<List<String>, NoParams> {
  const GetStopLog(this._repo);

  final StopLogRepository _repo;

  @override
  Future<List<String>> call(NoParams _) => _repo.read();
}

class ClearStopLog implements UseCase<void, NoParams> {
  const ClearStopLog(this._repo);

  final StopLogRepository _repo;

  @override
  Future<void> call(NoParams _) => _repo.clear();
}
