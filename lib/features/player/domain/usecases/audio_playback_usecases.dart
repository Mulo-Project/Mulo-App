import '../../../../core/usecase/usecase.dart';
import '../entities/playback_snapshot.dart';
import '../repositories/audio_player_repository.dart';

class WatchAudioPosition implements StreamUseCase<Duration, NoParams> {
  const WatchAudioPosition(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Stream<Duration> call(NoParams params) => _repo.watchPosition();
}

class WatchAudioTrackChange
    implements StreamUseCase<PlaybackTrackChange, NoParams> {
  const WatchAudioTrackChange(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Stream<PlaybackTrackChange> call(NoParams params) => _repo.watchTrackChange();
}

class WatchAudioEnded implements StreamUseCase<void, NoParams> {
  const WatchAudioEnded(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Stream<void> call(NoParams params) => _repo.watchEnded();
}

class WatchAudioPlaying implements StreamUseCase<bool, NoParams> {
  const WatchAudioPlaying(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Stream<bool> call(NoParams params) => _repo.watchPlaying();
}

class WatchOpenPlayer implements StreamUseCase<void, NoParams> {
  const WatchOpenPlayer(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Stream<void> call(NoParams params) => _repo.watchOpenPlayer();
}

class SetAudioQueue implements UseCase<void, PlaybackSnapshot> {
  const SetAudioQueue(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<void> call(PlaybackSnapshot snapshot) => _repo.setQueue(snapshot);
}

class SkipAudioTo implements UseCase<void, int> {
  const SkipAudioTo(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<void> call(int index) => _repo.skipTo(index);
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

/// 구간 반복: 시작 · 끝 (둘 다 null이면 해제).
typedef AudioLoopRange = ({Duration? start, Duration? end});

class SetAudioLoop implements UseCase<void, AudioLoopRange> {
  const SetAudioLoop(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<void> call(AudioLoopRange range) =>
      _repo.setLoop(range.start, range.end);
}

class RestoreAudioQueue implements UseCase<PlaybackSnapshot?, NoParams> {
  const RestoreAudioQueue(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<PlaybackSnapshot?> call(NoParams params) => _repo.restore();
}

class TakeOpenPlayerRequest implements UseCase<bool, NoParams> {
  const TakeOpenPlayerRequest(this._repo);
  final AudioPlayerRepository _repo;

  @override
  Future<bool> call(NoParams params) => _repo.takeOpenPlayerRequest();
}

/// 재생 엔진을 다루는 유스케이스 묶음 (재생 상태 Cubit이 한 번에 받는다).
class AudioPlayback {
  const AudioPlayback({
    required this.watchPosition,
    required this.watchTrackChange,
    required this.watchEnded,
    required this.watchPlaying,
    required this.watchOpenPlayer,
    required this.setQueue,
    required this.skipTo,
    required this.play,
    required this.pause,
    required this.seek,
    required this.setLoop,
    required this.restore,
    required this.takeOpenPlayerRequest,
  });

  final WatchAudioPosition watchPosition;
  final WatchAudioTrackChange watchTrackChange;
  final WatchAudioEnded watchEnded;
  final WatchAudioPlaying watchPlaying;
  final WatchOpenPlayer watchOpenPlayer;
  final SetAudioQueue setQueue;
  final SkipAudioTo skipTo;
  final PlayAudio play;
  final PauseAudio pause;
  final SeekAudio seek;
  final SetAudioLoop setLoop;
  final RestoreAudioQueue restore;
  final TakeOpenPlayerRequest takeOpenPlayerRequest;
}
