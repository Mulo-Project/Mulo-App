import '../../../../core/usecase/usecase.dart';
import '../entities/output_behavior.dart';
import '../repositories/output_behavior_repository.dart';

class LoadOutputBehavior implements UseCase<OutputBehavior, NoParams> {
  const LoadOutputBehavior(this._repo);

  final OutputBehaviorRepository _repo;

  @override
  Future<OutputBehavior> call(NoParams _) async {
    final value = await _repo.load();
    await _repo.apply(value);
    return value;
  }
}

class SaveOutputBehavior implements UseCase<void, OutputBehavior> {
  const SaveOutputBehavior(this._repo);

  final OutputBehaviorRepository _repo;

  @override
  Future<void> call(OutputBehavior value) => _repo.save(value);
}
