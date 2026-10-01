import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_lock_settings.dart';
import '../../domain/repositories/app_lock_repository.dart';

/// PIN은 솔트 + SHA-256 해시로만 보안 저장소(Keystore)에 두고,
/// 켜짐 · 생체 인증 여부는 shared_preferences에 둔다.
class SecureAppLockRepository implements AppLockRepository {
  SecureAppLockRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _enabledKey = 'security.appLock';
  static const _biometricKey = 'security.biometric';
  static const _saltKey = 'security.pinSalt';
  static const _hashKey = 'security.pinHash';

  final FlutterSecureStorage _storage;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<AppLockSettings> load() async {
    final prefs = await _prefs;
    final enabled = prefs.getBool(_enabledKey) ?? false;
    return AppLockSettings(
      enabled: enabled,
      biometricEnabled: enabled && (prefs.getBool(_biometricKey) ?? false),
    );
  }

  @override
  Future<void> enable(String pin) async {
    final salt = _newSalt();
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: _hash(salt, pin));
    await (await _prefs).setBool(_enabledKey, true);
  }

  @override
  Future<void> disable() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _hashKey);
    final prefs = await _prefs;
    await prefs.setBool(_enabledKey, false);
    await prefs.setBool(_biometricKey, false);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    final hash = await _storage.read(key: _hashKey);
    if (salt == null || hash == null) return false;
    return _hash(salt, pin) == hash;
  }

  @override
  Future<void> setBiometric(bool enabled) async =>
      (await _prefs).setBool(_biometricKey, enabled);

  static String _newSalt() {
    final rnd = Random.secure();
    return base64Url.encode(List.generate(16, (_) => rnd.nextInt(256)));
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
