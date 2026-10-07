import '../../../../core/usecase/usecase.dart';
import '../entities/app_permission.dart';
import '../repositories/permission_repository.dart';

class GetSupportedPermissions {
  const GetSupportedPermissions(this._repo);
  final PermissionRepository _repo;

  List<AppPermission> call() => _repo.supported;
}

class GetPermissionLevel implements UseCase<PermissionLevel, AppPermission> {
  const GetPermissionLevel(this._repo);
  final PermissionRepository _repo;

  @override
  Future<PermissionLevel> call(AppPermission params) => _repo.status(params);
}

class RequestAppPermission implements UseCase<PermissionLevel, AppPermission> {
  const RequestAppPermission(this._repo);
  final PermissionRepository _repo;

  @override
  Future<PermissionLevel> call(AppPermission params) => _repo.request(params);
}

class OpenPermissionSettings implements UseCase<void, NoParams> {
  const OpenPermissionSettings(this._repo);
  final PermissionRepository _repo;

  @override
  Future<void> call(NoParams params) => _repo.openSystemSettings();
}
