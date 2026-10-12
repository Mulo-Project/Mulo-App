import '../../../../core/usecase/usecase.dart';
import '../entities/audio_output.dart';
import '../repositories/audio_output_repository.dart';

class GetAudioOutput implements UseCase<AudioOutput?, NoParams> {
  const GetAudioOutput(this._repo);

  final AudioOutputRepository _repo;

  @override
  Future<AudioOutput?> call(NoParams params) => _repo.current();
}

class WatchAudioOutputChanges implements UseCase<Stream<void>, NoParams> {
  const WatchAudioOutputChanges(this._repo);

  final AudioOutputRepository _repo;

  @override
  Future<Stream<void>> call(NoParams params) async => _repo.watchChanges();
}
