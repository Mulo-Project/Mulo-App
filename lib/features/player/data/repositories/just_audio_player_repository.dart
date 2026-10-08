import 'dart:async';

import '../../domain/repositories/audio_player_repository.dart';
import '../datasources/audio_engine_source.dart';

class JustAudioPlayerRepository implements AudioPlayerRepository {
  JustAudioPlayerRepository(this._source);

  final AudioEngineSource _source;

  @override
  Stream<Duration> watchPosition() => _source.position;

  @override
  Stream<void> watchCompleted() => _source.completed;

  @override
  Stream<bool> watchPlaying() => _source.playing;

  @override
  Future<void> load(String uri) => _source.load(uri);

  // just_audio의 play()는 곡이 끝날 때까지 끝나지 않아 기다리지 않는다.
  @override
  Future<void> play() async {
    unawaited(_source.play());
  }

  @override
  Future<void> pause() => _source.pause();

  @override
  Future<void> seek(Duration position) => _source.seek(position);
}
