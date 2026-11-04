import 'dart:io';

import '../../../../core/platform/native_playback_channel.dart';
import '../../domain/repositories/stop_log_repository.dart';

/// Android 재생 서비스가 남긴 중단 기록(`PlaybackStore.logStop`)을 채널로 읽는다. 그 밖의 OS는 항상 비어 있다.
class NativeStopLogRepository implements StopLogRepository {
  NativeStopLogRepository(this._channel);

  final NativePlaybackChannel _channel;

  @override
  Future<List<String>> read() async {
    if (!Platform.isAndroid) return const [];
    try {
      return await _channel.stopLog();
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> clear() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.clearStopLog();
    } on Object {
      // 지우지 못해도 다음에 다시 지울 수 있다.
    }
  }
}
