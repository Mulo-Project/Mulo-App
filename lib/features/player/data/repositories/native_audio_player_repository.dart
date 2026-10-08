import 'dart:io';

import '../../../../core/platform/native_playback_channel.dart';
import '../../domain/repositories/audio_player_repository.dart';

/// Android 재생 엔진: 네이티브 서비스(ExoPlayer)가 소리를 낸다.
/// 다른 앱에 오디오 포커스를 뺏겨 멈추면 [watchPlaying]으로 알려 준다.
class NativeAudioPlayerRepository implements AudioPlayerRepository {
  NativeAudioPlayerRepository(this._channel);

  final NativePlaybackChannel _channel;

  @override
  Stream<Duration> watchPosition() => _channel.events
      .where((e) => e['type'] == 'position')
      .map((e) => Duration(milliseconds: (e['ms'] as num).toInt()));

  @override
  Stream<void> watchCompleted() =>
      _channel.events.where((e) => e['type'] == 'completed');

  @override
  Stream<bool> watchPlaying() => _channel.events
      .where((e) => e['type'] == 'playing')
      .map((e) => e['value'] == true);

  @override
  Future<void> load(String uri) => _channel.load(
    uri.contains('://')
        ? uri
        : Uri.file(uri, windows: Platform.isWindows).toString(),
  );

  @override
  Future<void> play() => _channel.play();

  @override
  Future<void> pause() => _channel.pause();

  @override
  Future<void> seek(Duration position) => _channel.seek(position);
}
