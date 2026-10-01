import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/repositories/app_lock_repository.dart';

/// local_auth로 기기 생체 인증(지문 · 얼굴)을 부른다.
class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
