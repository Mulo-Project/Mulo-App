import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/design/tokens/app_palette.dart';
import '../../domain/repositories/download_notifier.dart';
import '../datasources/notification_texts.dart';

/// Android 알림창에 받기 진행 · 결과를 띄운다 (flutter_local_notifications).
/// 받는 중 알림은 [showProgress]의 `foreground`가 true일 때 포그라운드 서비스(dataSync)로 띄워
/// 앱이 뒤로 가거나 닫혀도 받기가 이어지게 한다. 알림의 미리 듣기 버튼은 앱을 앞으로 가져와 [watchActions]로 알린다.
class LocalDownloadNotifier implements DownloadNotifier {
  static const _icon = 'ic_stat_mulo';
  static const _progressId = 2001;
  static const _previewAction = 'preview';
  static const _progressChannel = 'com.mulo.app.download_progress';
  static const _doneChannel = 'com.mulo.app.download_done';
  static const _failedChannel = 'com.mulo.app.download_failed';

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _init;
  var _foreground = false;
  final _resultIds = <int>{};
  final _actions = StreamController<DownloadNotificationAction>.broadcast();

  @override
  Stream<DownloadNotificationAction> watchActions() => _actions.stream;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _ensureInit() => _init ??= _initialize();

  Future<void> _initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == _previewAction) {
          _actions.add(DownloadNotificationAction.preview);
        }
      },
    );
    final l10n = systemL10n();
    final android = _android;
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _progressChannel,
        l10n.notifChannelDownloadProgress,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _doneChannel,
        l10n.notifChannelDownloadDone,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _failedChannel,
        l10n.notifChannelDownloadFailed,
        importance: Importance.defaultImportance,
      ),
    );
  }

  AndroidNotificationDetails _progressDetails(
    int? percent, {
    String? subText,
    String? previewLabel,
  }) => AndroidNotificationDetails(
    _progressChannel,
    systemL10n().notifChannelDownloadProgress,
    icon: _icon,
    color: AppPalette.violet,
    importance: Importance.low,
    priority: Priority.low,
    category: AndroidNotificationCategory.progress,
    ongoing: true,
    onlyAlertOnce: true,
    showProgress: true,
    maxProgress: 100,
    progress: percent ?? 0,
    indeterminate: percent == null,
    playSound: false,
    enableVibration: false,
    showWhen: false,
    subText: subText,
    actions: [
      if (previewLabel != null)
        AndroidNotificationAction(
          _previewAction,
          previewLabel,
          showsUserInterface: true,
          cancelNotification: false,
        ),
    ],
    visibility: NotificationVisibility.private,
  );

  @override
  Future<void> showProgress({
    required String title,
    required String body,
    int? percent,
    bool foreground = true,
    String? subText,
    String? previewLabel,
  }) async {
    await _ensureInit();
    final details = _progressDetails(
      percent,
      subText: subText,
      previewLabel: previewLabel,
    );
    // 앞에 붙들기를 끈 경우: 서비스를 내리고 보통 알림으로 보인다.
    if (!foreground) {
      if (_foreground) {
        _foreground = false;
        await _android?.stopForegroundService();
      }
      await _plugin.show(
        _progressId,
        title,
        body,
        NotificationDetails(android: details),
      );
      return;
    }
    if (_foreground) {
      await _plugin.show(
        _progressId,
        title,
        body,
        NotificationDetails(android: details),
      );
      return;
    }
    final android = _android;
    if (android == null) return;
    await android.startForegroundService(
      _progressId,
      title,
      body,
      notificationDetails: details,
      foregroundServiceTypes: {
        AndroidServiceForegroundType.foregroundServiceTypeDataSync,
      },
    );
    _foreground = true;
  }

  @override
  Future<void> clearProgress() async {
    if (_init == null) return;
    await _ensureInit();
    if (_foreground) {
      _foreground = false;
      await _android?.stopForegroundService();
    }
    await _plugin.cancel(_progressId);
  }

  @override
  Future<void> showResult({
    required String id,
    required String title,
    required String body,
    required bool failed,
  }) async {
    await _ensureInit();
    final l10n = systemL10n();
    final notificationId = 3000 + (id.hashCode & 0xFFFFF);
    _resultIds.add(notificationId);
    await _plugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          failed ? _failedChannel : _doneChannel,
          failed
              ? l10n.notifChannelDownloadFailed
              : l10n.notifChannelDownloadDone,
          icon: _icon,
          color: AppPalette.violet,
          importance: failed ? Importance.defaultImportance : Importance.low,
          priority: failed ? Priority.defaultPriority : Priority.low,
          category: AndroidNotificationCategory.status,
          autoCancel: true,
          styleInformation: BigTextStyleInformation(body),
          visibility: NotificationVisibility.private,
        ),
      ),
    );
  }

  @override
  Future<void> clearResults() async {
    if (_init == null) return;
    for (final id in _resultIds) {
      await _plugin.cancel(id);
    }
    _resultIds.clear();
  }
}
