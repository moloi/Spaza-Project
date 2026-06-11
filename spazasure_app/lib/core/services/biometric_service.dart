import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles biometric authentication (fingerprint/face ID).
/// Stores refresh token securely and unlocks it via biometric.
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const _refreshTokenKey = 'secure_refresh_token';
  static const _biometricEnabledKey = 'biometric_enabled';

  /// Check if biometric authentication is available on this device.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, iris).
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate user via biometrics.
  static Future<bool> authenticate({String reason = 'Verify your identity to access SpazaSure'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Enable biometric login by storing the refresh token securely.
  static Future<void> enable(String refreshToken) async {
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
  }

  /// Disable biometric login.
  static Future<void> disable() async {
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
  }

  /// Check if biometric login is enabled by the user.
  static Future<bool> isEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Get the stored refresh token (after biometric verification).
  static Future<String?> getSecureRefreshToken() async {
    final authenticated = await authenticate();
    if (!authenticated) return null;
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Update the stored token (call after token refresh).
  static Future<void> updateToken(String newToken) async {
    final enabled = await isEnabled();
    if (enabled) {
      await _secureStorage.write(key: _refreshTokenKey, value: newToken);
    }
  }
}
