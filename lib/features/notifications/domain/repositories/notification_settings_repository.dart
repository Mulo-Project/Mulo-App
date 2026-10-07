import '../entities/notification_settings.dart';

abstract interface class NotificationSettingsRepository {
  Future<NotificationSettings> load();

  Future<void> save(NotificationSettings settings);

  /// 시스템 알림 권한이 허용돼 있는지 (권한이 필요 없는 OS는 항상 true).
  Future<bool> isPermissionGranted();

  /// 시스템 알림 권한을 요청한다. 허용되면 true.
  Future<bool> requestPermission();

  /// 이 앱의 시스템 알림 설정 화면을 연다 (권한을 영구 거절했을 때).
  Future<void> openSystemSettings();
}
