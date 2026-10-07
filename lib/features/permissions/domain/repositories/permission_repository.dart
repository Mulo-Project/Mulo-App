import '../entities/app_permission.dart';

abstract interface class PermissionRepository {
  /// 이 기기에서 따로 허용이 필요한 권한. 필요한 게 없으면 빈 목록.
  List<AppPermission> get supported;

  Future<PermissionLevel> status(AppPermission permission);

  /// 시스템 요청 창을 띄우고 결과 상태를 돌려준다.
  Future<PermissionLevel> request(AppPermission permission);

  Future<void> openSystemSettings();
}
