import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/platform/native_playback_channel.dart';
import '../../domain/repositories/mix_with_others_repository.dart';

/// shared_preferences에 저장하고, Android 재생 서비스(ExoPlayer)의 오디오 포커스 처리에 반영한다.
/// 그 밖의 OS는 저장만 한다.
class PrefsMixWithOthersRepository implements MixWithOthersRepository {
  PrefsMixWithOthersRepository(this._channel);

  static const _key = 'player.mixWithOthers';

  final NativePlaybackChannel _channel;

  @override
  Future<bool> load() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> save(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(_key, value);
    await apply(value);
  }

  @override
  Future<void> apply(bool value) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.setMixWithOthers(value);
    } on Object {
      // 재생 서비스를 못 부르면 다음 시작 때 다시 반영된다.
    }
  }
}
