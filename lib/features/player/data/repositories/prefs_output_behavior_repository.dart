import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/platform/native_playback_channel.dart';
import '../../domain/entities/output_behavior.dart';
import '../../domain/repositories/output_behavior_repository.dart';

/// shared_preferences에 저장하고, Android 재생 서비스에 전한다 (멈춤 · 이어 재생은 네이티브가 처리).
/// 그 밖의 OS는 저장만 한다.
class PrefsOutputBehaviorRepository implements OutputBehaviorRepository {
  PrefsOutputBehaviorRepository(this._channel);

  static const _pauseKey = 'player.pauseOnDisconnect';
  static const _resumeKey = 'player.resumeOnConnect';

  final NativePlaybackChannel _channel;

  @override
  Future<OutputBehavior> load() async {
    final prefs = await SharedPreferences.getInstance();
    return OutputBehavior(
      pauseOnDisconnect: prefs.getBool(_pauseKey) ?? true,
      resumeOnConnect: prefs.getBool(_resumeKey) ?? false,
    );
  }

  @override
  Future<void> save(OutputBehavior value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pauseKey, value.pauseOnDisconnect);
    await prefs.setBool(_resumeKey, value.resumeOnConnect);
    await apply(value);
  }

  @override
  Future<void> apply(OutputBehavior value) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.setOutputBehavior(
        pauseOnDisconnect: value.pauseOnDisconnect,
        resumeOnConnect: value.resumeOnConnect,
      );
    } on Object {
      // 재생 서비스를 못 부르면 다음 시작 때 다시 반영된다.
    }
  }
}
