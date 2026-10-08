import '../../../../core/usecase/usecase.dart';
import '../repositories/audio_player_repository.dart';

class WatchAudioPosition implements StreamUseCase<Duration, NoParams> {
  const WatchAudioPosition(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Stream<Duration> call(NoParams params) => _repo.watchPosition();
}

class WatchAudioCompleted implements StreamUseCase<void, NoParams> {
  const WatchAudioCompleted(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Stream<void> call(NoParams params) => _repo.watchCompleted();
}

class WatchAudioPlaying implements StreamUseCase<bool, NoParams> {
  const WatchAudioPlaying(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Stream<bool> call(NoParams params) => _repo.watchPlaying();
}

class LoadAudio implements UseCase<void, String> {
  const LoadAudio(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<void> call(String uri) => _repo.load(uri);
}

class PlayAudio implements UseCase<void, NoParams> {
  const PlayAudio(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<void> call(NoParams params) => _repo.play();
}

class PauseAudio implements UseCase<void, NoParams> {
  const PauseAudio(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<void> call(NoParams params) => _repo.pause();
}

class SeekAudio implements UseCase<void, Duration> {
  const SeekAudio(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<void> call(Duration position) => _repo.seek(position);
}

/// 재생 엔진을 다루는 유스케이스 묶음 (재생 상태 Cubit이 한 번에 받는다).
class AudioPlayback {
  const AudioPlayback({
    required this.watchPosition,
    required this.watchCompleted,
    required this.watchPlaying,
    required this.load,
    required this.play,
    required this.pause,
    required this.seek,
  });

  final WatchAudioPosition watchPosition;
  final WatchAudioCompleted watchCompleted;
  final WatchAudioPlaying watchPlaying;
  final LoadAudio load;
  final PlayAudio play;
  final PauseAudio pause;
  final SeekAudio seek;
}
