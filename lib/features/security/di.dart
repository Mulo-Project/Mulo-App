import 'package:get_it/get_it.dart';

import 'data/datasources/local_biometric_authenticator.dart';
import 'data/repositories/secure_app_lock_repository.dart';
import 'domain/repositories/app_lock_repository.dart';
import 'domain/usecases/app_lock_usecases.dart';
import 'presentation/bloc/app_lock_cubit.dart';

/// 보안(앱 잠금) 기능 의존성. 테스트는 [AppLockRepository] ·
/// [BiometricAuthenticator]만 바꿔 끼운다.
void registerSecurity(GetIt sl) {
  sl
    ..registerLazySingleton<AppLockRepository>(SecureAppLockRepository.new)
    ..registerLazySingleton<BiometricAuthenticator>(
      LocalBiometricAuthenticator.new,
    )
    ..registerFactory(() => LoadAppLock(sl()))
    ..registerFactory(() => EnableAppLock(sl()))
    ..registerFactory(() => DisableAppLock(sl()))
    ..registerFactory(() => TurnOffAppLock(sl()))
    ..registerFactory(() => VerifyPin(sl()))
    ..registerFactory(() => SetBiometric(sl()))
    ..registerFactory(() => IsBiometricAvailable(sl()))
    ..registerFactory(() => AuthenticateBiometric(sl()))
    ..registerFactory(
      () => AppLockCubit(
        load: sl(),
        enable: sl(),
        disable: sl(),
        turnOff: sl(),
        verify: sl(),
        setBiometric: sl(),
        isBiometricAvailable: sl(),
        authenticateBiometric: sl(),
      ),
    );
}
