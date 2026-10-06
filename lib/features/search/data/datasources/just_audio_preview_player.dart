import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/engine_exception.dart';
import '../../domain/repositories/preview_player.dart';

/// 미리 듣기용 just_audio 플레이어. 메인 재생의 플레이어와는 별개라 대기열 · 미니 플레이어에
/// 끼어들지 않는다. 플레이어는 처음 쓸 때 만든다.
class JustAudioPreviewPlayer implements PreviewPlayer {
  AudioPlayer? _player;
  final _completed = StreamController<void>.broadcast();
  StreamSubscription<ProcessingState>? _processing;

  AudioPlayer _ensure() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _processing = player.processingStateStream
        .where((s) => s == ProcessingState.completed)
        .listen((_) => _completed.add(null));
    return _player = player;
  }

  @override
  Future<void> play(AudioStream stream) async {
    final player = _ensure();
    try {
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(stream.url),
          headers: stream.headers.isEmpty ? null : stream.headers,
        ),
      );
    } on PlayerInterruptedException {
      // 불러오는 중에 멈춤 · 다른 곡으로 바뀜: 호출한 쪽이 이미 알고 있다.
      return;
    } on PlayerException catch (e) {
      throw EngineException(EngineFailure.failed, e.message ?? '');
    } on FormatException catch (e) {
      throw EngineException(EngineFailure.failed, e.message);
    }
    // 재생은 곡 끝까지 끝나지 않는 Future라 기다리지 않는다.
    unawaited(player.play());
  }

  @override
  Future<void> stop() async {
    // 불러오는 중이어도 멈출 수 있다 (진행 중이던 setAudioSource가 중단된다).
    await _player?.stop();
  }

  @override
  Stream<void> watchCompleted() => _completed.stream;

  Future<void> dispose() async {
    await _processing?.cancel();
    await _player?.dispose();
    _player = null;
    await _completed.close();
  }
}
