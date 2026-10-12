import '../../../../core/usecase/usecase.dart';
import '../repositories/mix_with_others_repository.dart';

class LoadMixWithOthers implements UseCase<bool, NoParams> {
  const LoadMixWithOthers(this._repo);

  final MixWithOthersRepository _repo;

  @override
  Future<bool> call(NoParams _) async {
    final value = await _repo.load();
    await _repo.apply(value);
    return value;
  }
}

class SaveMixWithOthers implements UseCase<void, bool> {
  const SaveMixWithOthers(this._repo);

  final MixWithOthersRepository _repo;

  @override
  Future<void> call(bool value) => _repo.save(value);
}
