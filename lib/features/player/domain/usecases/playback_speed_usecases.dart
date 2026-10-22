import '../../../../core/usecase/usecase.dart';
import '../repositories/playback_speed_repository.dart';

class LoadPlaybackSpeed implements UseCase<double, NoParams> {
  const LoadPlaybackSpeed(this._repo);

  final PlaybackSpeedRepository _repo;

  @override
  Future<double> call(NoParams _) async {
    final value = await _repo.load();
    await _repo.apply(value);
    return value;
  }
}

class SavePlaybackSpeed implements UseCase<void, double> {
  const SavePlaybackSpeed(this._repo);

  final PlaybackSpeedRepository _repo;

  @override
  Future<void> call(double value) => _repo.save(value);
}
