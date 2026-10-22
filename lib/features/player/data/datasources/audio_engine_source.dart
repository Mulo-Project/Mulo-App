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

/// 한 번에 한 곡만 다루는 재생 엔진.
abstract interface class AudioEngineSource {
  Stream<Duration> get position;

  Stream<bool> get playing;

  /// 곡 끝까지 재생했을 때마다 한 번씩.
  Stream<void> get completed;

  Future<void> load(String uri);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  /// 재생 속도 (음높이는 그대로). 곡을 바꿔도 유지된다.
  Future<void> setSpeed(double speed);
}

/// just_audio 플레이어 하나를 감싼다.
class JustAudioEngineSource implements AudioEngineSource {
  JustAudioEngineSource() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<bool> get playing => _player.playingStream;

  @override
  Stream<void> get completed => _player.processingStateStream.where(
    (s) => s == ProcessingState.completed,
  );

  /// Android `content://` 등 주소는 그대로, 데스크톱 파일 경로는 파일로 연다.
  @override
  Future<void> load(String uri) async {
    final source = uri.contains('://')
        ? Uri.parse(uri)
        : Uri.file(uri, windows: Platform.isWindows);
    await _player.setAudioSource(AudioSource.uri(source));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> dispose() => _player.dispose();
}
