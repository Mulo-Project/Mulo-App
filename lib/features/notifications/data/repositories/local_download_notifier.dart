import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/design/tokens/app_palette.dart';
import '../../domain/repositories/download_notifier.dart';
import '../datasources/notification_texts.dart';

/// Android 알림창에 받기 결과(끝남 · 실패)를 띄운다 (flutter_local_notifications).
/// 받는 동안의 진행 알림과 포그라운드 서비스는 없다: 받기는 앱이 켜져 있는 동안만 한다 (D-091).
class LocalDownloadNotifier implements DownloadNotifier {
  static const _icon = 'ic_stat_mulo';
  static const _doneChannel = 'com.mulo.app.download_done';
  static const _failedChannel = 'com.mulo.app.download_failed';

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _init;
  final _resultIds = <int>{};

  Future<void> _ensureInit() => _init ??= _initialize();

  Future<void> _initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
    );
    final l10n = systemL10n();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
