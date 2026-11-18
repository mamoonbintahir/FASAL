import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive values (auth tokens) in the platform keystore/keychain.
/// Never put tokens in SharedPreferences.
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null; // keystore unavailable (e.g. tests) — treat as signed out
    }
  }

  Future<void> writeToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }
}
