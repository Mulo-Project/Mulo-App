import '../entities/media_session_info.dart';

/// 재생 알림 · 잠금화면 · 이어폰 버튼.
abstract interface class MediaSession {
  /// 알림 · 잠금화면에서 누른 조작.
  Stream<MediaCommand> watchCommands();

  /// 보여 줄 재생 상태를 갱신한다. null이면 알림을 치운다.
  Future<void> update(MediaSessionInfo? info);
}
