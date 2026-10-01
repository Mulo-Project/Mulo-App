import '../entities/app_lock_settings.dart';

/// 앱 잠금 저장소 (켜짐 여부 · 생체 인증 사용 · PIN).
abstract interface class AppLockRepository {
  Future<AppLockSettings> load();

  /// PIN을 정하고 잠금을 켠다.
  Future<void> enable(String pin);

  /// 잠금을 끄고 PIN을 지운다.
  Future<void> disable();

  Future<bool> verifyPin(String pin);
  Future<void> setBiometric(bool enabled);
}

/// 기기 생체 인증(지문 · 얼굴).
abstract interface class BiometricAuthenticator {
  /// 기기에 생체 인증이 등록돼 쓸 수 있는지.
  Future<bool> isAvailable();

  /// 인증 창을 띄운다. 성공하면 true.
  Future<bool> authenticate(String reason);
}
