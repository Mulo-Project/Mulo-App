import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/app_permission.dart';
import '../../domain/repositories/permission_repository.dart';

/// permission_handler로 Android 시스템 권한을 읽고 요청한다. 다른 OS는 따로 허용할 권한이 없다.
class SystemPermissionRepository implements PermissionRepository {
  @override
  List<AppPermission> get supported =>
      Platform.isAndroid ? AppPermission.values : const [];

  /// 음악 · 영상 파일은 Android 13+는 audio · videos, 12 이하는 storage 권한이다. 기기에 맞는 쪽만 실제로 뜬다.
  List<Permission> _of(AppPermission p) => switch (p) {
    AppPermission.notifications => [Permission.notification],
    AppPermission.audio => [
      Permission.audio,
      Permission.videos,
      Permission.storage,
    ],
    AppPermission.overlay => [Permission.systemAlertWindow],
  };

  @override
  Future<PermissionLevel> status(AppPermission permission) async => _level(
    permission,
    {for (final p in _of(permission)) p: await p.status},
  );

  @override
  Future<PermissionLevel> request(AppPermission permission) async {
    final statuses = await _of(permission).request();
    return _level(permission, statuses);
  }

  /// 음악 · 영상은 둘 다 허용해야 허용이다 (영상만 거부하면 저장한 영상이 열리지 않는다).
  /// Android 12 이하는 storage 하나가 둘을 다 덮는다.
  static PermissionLevel _level(
    AppPermission permission,
    Map<Permission, PermissionStatus> statuses,
  ) {
    if (permission != AppPermission.audio) return _combine(statuses.values);
    bool ok(Permission p) =>
        statuses[p]?.isGranted == true || statuses[p]?.isLimited == true;
    if (ok(Permission.storage) || (ok(Permission.audio) && ok(Permission.videos))) {
      return PermissionLevel.granted;
    }
    return statuses.values.any((s) => s.isPermanentlyDenied)
        ? PermissionLevel.blocked
        : PermissionLevel.denied;
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
