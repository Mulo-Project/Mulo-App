import '../../../../core/usecase/usecase.dart';
import '../entities/app_lock_settings.dart';
import '../repositories/app_lock_repository.dart';

class LoadAppLock implements UseCase<AppLockSettings, NoParams> {
  const LoadAppLock(this._repo);

  final AppLockRepository _repo;

  @override
  Future<AppLockSettings> call(NoParams _) => _repo.load();
}

/// PIN을 정하고 잠금을 켠다. 4~6자리 숫자가 아니면 [ArgumentError].
class EnableAppLock implements UseCase<void, String> {
  const EnableAppLock(this._repo);

  final AppLockRepository _repo;

  @override
  Future<void> call(String pin) async {
    if (!AppLockSettings.isValidPin(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN은 4~6자리 숫자');
    }
    await _repo.enable(pin);
  }
}

/// 현재 PIN이 맞으면 잠금을 끈다. 맞으면 true.
class DisableAppLock implements UseCase<bool, String> {
  const DisableAppLock(this._repo);

  final AppLockRepository _repo;

  @override
  Future<bool> call(String pin) async {
    if (!await _repo.verifyPin(pin)) return false;
    await _repo.disable();
    return true;
  }
}

/// 본인 확인(PIN 검증 또는 생체 인증)을 이미 마친 뒤 잠금을 끈다.
class TurnOffAppLock implements UseCase<void, NoParams> {
  const TurnOffAppLock(this._repo);

  final AppLockRepository _repo;

  @override
  Future<void> call(NoParams _) => _repo.disable();
}

class VerifyPin implements UseCase<bool, String> {
  const VerifyPin(this._repo);

  final AppLockRepository _repo;

  @override
  Future<bool> call(String pin) => _repo.verifyPin(pin);
}

class SetBiometric implements UseCase<void, bool> {
  const SetBiometric(this._repo);

  final AppLockRepository _repo;

  @override
  Future<void> call(bool enabled) => _repo.setBiometric(enabled);
}

class IsBiometricAvailable implements UseCase<bool, NoParams> {
  const IsBiometricAvailable(this._auth);

  final BiometricAuthenticator _auth;

  @override
  Future<bool> call(NoParams _) => _auth.isAvailable();
}

class AuthenticateBiometric implements UseCase<bool, String> {
  const AuthenticateBiometric(this._auth);

  final BiometricAuthenticator _auth;

  /// 인자는 인증 창에 보일 안내 문구.
  @override
  Future<bool> call(String reason) => _auth.authenticate(reason);
}
