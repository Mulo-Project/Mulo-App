import '../../../../core/usecase/usecase.dart';
import '../entities/media_session_info.dart';
import '../entities/notification_settings.dart';
import '../repositories/download_notifier.dart';
import '../repositories/media_session.dart';
import '../repositories/notification_settings_repository.dart';

class LoadNotificationSettings
    implements UseCase<NotificationSettings, NoParams> {
  const LoadNotificationSettings(this._repo);
  final NotificationSettingsRepository _repo;

  @override
  Future<NotificationSettings> call(NoParams params) => _repo.load();
}

class SaveNotificationSettings implements UseCase<void, NotificationSettings> {
  const SaveNotificationSettings(this._repo);
  final NotificationSettingsRepository _repo;

  @override
  Future<void> call(NotificationSettings params) => _repo.save(params);
}

class IsNotificationPermissionGranted implements UseCase<bool, NoParams> {
  const IsNotificationPermissionGranted(this._repo);
  final NotificationSettingsRepository _repo;

  @override
  Future<bool> call(NoParams params) => _repo.isPermissionGranted();
}

class RequestNotificationPermission implements UseCase<bool, NoParams> {
  const RequestNotificationPermission(this._repo);
  final NotificationSettingsRepository _repo;

  @override
  Future<bool> call(NoParams params) => _repo.requestPermission();
}

class OpenNotificationSystemSettings implements UseCase<void, NoParams> {
  const OpenNotificationSystemSettings(this._repo);
  final NotificationSettingsRepository _repo;

  @override
  Future<void> call(NoParams params) => _repo.openSystemSettings();
}

class DownloadProgressNotice {
  const DownloadProgressNotice({
    required this.title,
    required this.body,
    this.percent,
    this.foreground = true,
    this.subText,
    this.previewLabel,
    this.cancelLabel,
    this.pauseLabel,
    this.stopLabel,
  });

  final String title;
  final String body;
  final int? percent;
  final bool foreground;
  final String? subText;
  final String? previewLabel;
  final String? cancelLabel;
  final String? pauseLabel;
  final String? stopLabel;
}

class ShowDownloadProgress implements UseCase<void, DownloadProgressNotice> {
  const ShowDownloadProgress(this._notifier);
  final DownloadNotifier _notifier;

  @override
  Future<void> call(DownloadProgressNotice params) => _notifier.showProgress(
    title: params.title,
    body: params.body,
    percent: params.percent,
    foreground: params.foreground,
    subText: params.subText,
    previewLabel: params.previewLabel,
    cancelLabel: params.cancelLabel,
    pauseLabel: params.pauseLabel,
    stopLabel: params.stopLabel,
  );
}

class ClearDownloadProgress implements UseCase<void, NoParams> {
  const ClearDownloadProgress(this._notifier);
  final DownloadNotifier _notifier;

  @override
  Future<void> call(NoParams params) => _notifier.clearProgress();
}

class DownloadResultNotice {
  const DownloadResultNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.failed,
  });

  final String id;
  final String title;
  final String body;
  final bool failed;
}

class ShowDownloadResult implements UseCase<void, DownloadResultNotice> {
  const ShowDownloadResult(this._notifier);
  final DownloadNotifier _notifier;

  @override
  Future<void> call(DownloadResultNotice params) => _notifier.showResult(
    id: params.id,
    title: params.title,
    body: params.body,
    failed: params.failed,
  );
}

class ClearDownloadResults implements UseCase<void, NoParams> {
  const ClearDownloadResults(this._notifier);
  final DownloadNotifier _notifier;

  @override
  Future<void> call(NoParams params) => _notifier.clearResults();
}

class WatchDownloadActions
    implements StreamUseCase<DownloadNotificationAction, NoParams> {
  const WatchDownloadActions(this._notifier);
  final DownloadNotifier _notifier;

  @override
  Stream<DownloadNotificationAction> call(NoParams params) =>
      _notifier.watchActions();
}

class WatchMediaCommands implements StreamUseCase<MediaCommand, NoParams> {
  const WatchMediaCommands(this._session);
  final MediaSession _session;

  @override
  Stream<MediaCommand> call(NoParams params) => _session.watchCommands();
}

class UpdateMediaSession implements UseCase<void, MediaSessionInfo?> {
  const UpdateMediaSession(this._session);
  final MediaSession _session;

  @override
  Future<void> call(MediaSessionInfo? params) => _session.update(params);
}

/// 알림 유스케이스 묶음 (알림 동기화 Cubit이 한 번에 받는다).
class NotificationActions {
  const NotificationActions({
    required this.showProgress,
    required this.clearProgress,
    required this.showResult,
    required this.clearResults,
    required this.watchCommands,
    required this.watchDownloadActions,
    required this.updateSession,
    required this.isPermissionGranted,
    required this.requestPermission,
  });

  final ShowDownloadProgress showProgress;
  final ClearDownloadProgress clearProgress;
  final ShowDownloadResult showResult;
  final ClearDownloadResults clearResults;
  final WatchMediaCommands watchCommands;
  final WatchDownloadActions watchDownloadActions;
  final UpdateMediaSession updateSession;
  final IsNotificationPermissionGranted isPermissionGranted;
  final RequestNotificationPermission requestPermission;
}
