import '../../domain/entities/media_session_info.dart';
import '../../domain/repositories/download_notifier.dart';
import '../../domain/repositories/media_session.dart';

/// 알림창이 없는 OS (Windows · Linux · macOS)용: 아무것도 띄우지 않는다.
class NoDownloadNotifier implements DownloadNotifier {
  @override
  Stream<DownloadNotificationAction> watchActions() => const Stream.empty();

  @override
  Future<void> showProgress({
    required String title,
    required String body,
    int? percent,
    bool foreground = true,
    String? subText,
    String? previewLabel,
    String? cancelLabel,
    String? pauseLabel,
    String? stopLabel,
  }) async {}

  @override
  Future<void> clearProgress() async {}

  @override
  Future<void> showResult({
    required String id,
    required String title,
    required String body,
    required bool failed,
  }) async {}

  @override
  Future<void> clearResults() async {}
}

class NoMediaSession implements MediaSession {
  @override
  Stream<MediaCommand> watchCommands() => const Stream.empty();

  @override
  Future<void> update(MediaSessionInfo? info) async {}

  @override
  Future<void> updateQueueArt(Map<String, String> artById) async {}
}
