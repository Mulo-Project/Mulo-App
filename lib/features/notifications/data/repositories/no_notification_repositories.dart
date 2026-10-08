import '../../domain/entities/media_session_info.dart';
import '../../domain/repositories/media_session.dart';

/// 알림창이 없는 OS (Windows · Linux · macOS)용: 아무것도 띄우지 않는다.
class NoMediaSession implements MediaSession {
  @override
  Stream<MediaCommand> watchCommands() => const Stream.empty();

  @override
  Future<void> update(MediaSessionInfo? info) async {}

  @override
  Future<void> updateQueueArt(Map<String, String> artById) async {}
}
