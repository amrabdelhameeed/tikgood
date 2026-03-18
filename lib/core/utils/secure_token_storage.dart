import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage using platform-specific secure storage.
///
/// Uses Android Keystore on Android and iOS Keychain on iOS
/// to encrypt tokens at rest — unlike Hive which stores plaintext.
class SecureTokenStorage {
  SecureTokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(),
  );

  // ──────────────── GuROW Auth Token ────────────────

  static const _tokenKey = 'tikgood_auth_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ──────────────── AF Securities Token ────────────────

  static const _afTokenKey = 'tikgood_extra_token';

  static Future<void> saveAfToken(String token) async {
    await _storage.write(key: _afTokenKey, value: token);
  }

  static Future<String?> getAfToken() async {
    return await _storage.read(key: _afTokenKey);
  }

  static Future<void> deleteAfToken() async {
    await _storage.delete(key: _afTokenKey);
  }

  // ──────────────── Clear All ────────────────

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
