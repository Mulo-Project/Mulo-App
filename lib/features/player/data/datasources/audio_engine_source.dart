import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

/// 앱을 켤 때 한 번: Windows · Linux는 just_audio 기본 구현이 없어 media_kit을 쓴다
/// (Android · macOS는 just_audio 자체 구현).
void initAudioBackend() {
  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(windows: true, linux: true);
  }
}

/// just_audio 플레이어 하나를 감싼다.
class AudioEngineSource {
  AudioEngineSource() : _player = AudioPlayer();

  final AudioPlayer _player;

  Stream<Duration> get position => _player.positionStream;

  Stream<void> get completed => _player.processingStateStream.where(
    (s) => s == ProcessingState.completed,
  );

  /// Android `content://` 등 주소는 그대로, 데스크톱 파일 경로는 파일로 연다.
  Future<void> load(String uri) async {
    final source = uri.contains('://')
        ? Uri.parse(uri)
        : Uri.file(uri, windows: Platform.isWindows);
    await _player.setAudioSource(AudioSource.uri(source));
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() => _player.dispose();
}
