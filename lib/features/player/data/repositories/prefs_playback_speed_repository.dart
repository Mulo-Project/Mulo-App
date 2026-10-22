import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/platform/native_playback_channel.dart';
import '../../domain/entities/playback_speed.dart';
import '../../domain/repositories/playback_speed_repository.dart';
import '../datasources/audio_engine_source.dart';

/// shared_preferences에 저장하고 재생 엔진에 반영한다.
/// Android는 네이티브 서비스(ExoPlayer)에, 그 밖의 OS는 just_audio에 건다.
class PrefsPlaybackSpeedRepository implements PlaybackSpeedRepository {
  PrefsPlaybackSpeedRepository(this._channel, this._engine);

  static const _key = 'player.playbackSpeed';

  final NativePlaybackChannel _channel;
  final AudioEngineSource _engine;

  @override
  Future<double> load() async => PlaybackSpeed.sanitize(
    (await SharedPreferences.getInstance()).getDouble(_key),
  );

  @override
  Future<void> save(double value) async {
    await (await SharedPreferences.getInstance()).setDouble(_key, value);
    await apply(value);
  }

  @override
  Future<void> apply(double value) async {
    try {
      if (Platform.isAndroid) {
        await _channel.setSpeed(value);
      } else {
        await _engine.setSpeed(value);
      }
    } on Object {
      // 엔진을 못 부르면 다음 시작 때 다시 반영된다.
    }
  }
}
