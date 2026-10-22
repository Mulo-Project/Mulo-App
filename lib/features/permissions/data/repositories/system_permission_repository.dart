import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/app_permission.dart';
import '../../domain/repositories/permission_repository.dart';

/// permission_handler로 Android 시스템 권한을 읽고 요청한다. 다른 OS는 따로 허용할 권한이 없다.
class SystemPermissionRepository implements PermissionRepository {
  @override
  List<AppPermission> get supported =>
      Platform.isAndroid ? AppPermission.values : const [];

  /// 음악 파일은 Android 13+는 audio, 12 이하는 storage 권한이다. 기기에 맞는 쪽만 실제로 뜬다.
  List<Permission> _of(AppPermission p) => switch (p) {
    AppPermission.notifications => [Permission.notification],
    AppPermission.audio => [Permission.audio, Permission.storage],
    AppPermission.overlay => [Permission.systemAlertWindow],
  };

  @override
  Future<PermissionLevel> status(AppPermission permission) async =>
      _combine([for (final p in _of(permission)) await p.status]);

  @override
  Future<PermissionLevel> request(AppPermission permission) async {
    final statuses = await _of(permission).request();
    return _combine(statuses.values);
  }

  @override
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  static PermissionLevel _combine(Iterable<PermissionStatus> statuses) {
    if (statuses.any((s) => s.isGranted || s.isLimited)) {
      return PermissionLevel.granted;
    }
    return statuses.any((s) => s.isPermanentlyDenied)
        ? PermissionLevel.blocked
        : PermissionLevel.denied;
  }
}
