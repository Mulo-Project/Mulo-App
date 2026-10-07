import 'package:get_it/get_it.dart';

import 'data/repositories/system_permission_repository.dart';
import 'domain/repositories/permission_repository.dart';
import 'domain/usecases/permission_usecases.dart';
import 'presentation/bloc/permissions_cubit.dart';

/// 권한 (설정의 권한 묶음) 의존성.
void registerPermissions(GetIt sl) {
  sl
    ..registerLazySingleton<PermissionRepository>(
      SystemPermissionRepository.new,
    )
    ..registerFactory(() => GetSupportedPermissions(sl()))
    ..registerFactory(() => GetPermissionLevel(sl()))
    ..registerFactory(() => RequestAppPermission(sl()))
    ..registerFactory(() => OpenPermissionSettings(sl()))
    ..registerFactory(
      () => PermissionsCubit(
        supported: sl(),
        level: sl(),
        request: sl(),
        openSettings: sl(),
      ),
    );
}
