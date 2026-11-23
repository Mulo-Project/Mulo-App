import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 보안 저장소의 문자열 하나 (테스트에서 바꿔 끼운다).
abstract interface class AuthStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureAuthStore implements AuthStore {
  const SecureAuthStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
