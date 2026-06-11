import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage using platform-level encryption.
/// Replaces SharedPreferences for sensitive tokens in production.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const _accessTokenKey = 'secure_access_token';
  static const _refreshTokenKey = 'secure_refresh_token';

  /// Store access token securely.
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Store refresh token securely.
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get access token.
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token.
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Clear all secure storage (on logout).
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
