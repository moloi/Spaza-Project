import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthSession? _session;
  bool _initialized = false;

  AuthSession? get session => _session;
  bool get isLoggedIn => _session != null;
  bool get initialized => _initialized;
  String get shopName => _session?.shopName ?? '';

  Future<void> init() async {
    _session = await AuthService.getSession();
    _initialized = true;
    notifyListeners();

    // If already logged in, register for push notifications
    if (_session != null) {
      _registerPushToken();
    }
  }

  // Step 1 — send OTP (login flow)
  Future<void> sendLoginOtp(String phone) async {
    await AuthService.sendOtp(phone, purpose: 'login');
  }

  // Step 1 — send OTP (registration flow)
  Future<void> sendRegisterOtp(String phone) async {
    await AuthService.sendOtp(phone, purpose: 'registration');
  }

  // Step 2 — verify OTP + login
  Future<void> verifyLogin(String phone, String otp) async {
    _session = await AuthService.verifyLogin(phone, otp);
    notifyListeners();
    _registerPushToken();
  }

  // Step 2 — verify OTP + register
  Future<void> verifyRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String shopName,
    required String address,
    String? idNumber,
  }) async {
    _session = await AuthService.verifyRegister(
      phone: phone,
      otp: otp,
      fullName: fullName,
      shopName: shopName,
      address: address,
      idNumber: idNumber,
    );
    notifyListeners();
    _registerPushToken();
  }

  Future<void> logout() async {
    // Unregister push token before clearing session
    try {
      await PushNotificationService.unregister();
    } catch (_) {}

    await AuthService.logout();
    _session = null;
    notifyListeners();
  }

  /// Handle session expiry — call this when a SessionExpiredException is caught.
  void handleSessionExpired() {
    _session = null;
    AuthService.logout();
    notifyListeners();
  }

  // Demo login — bypasses API for testing
  Future<void> demoLogin() async {
    _session = AuthSession(
      userId: 'demo-001',
      shopName: "Thabo's Spaza Shop",
      phone: '+27812345678',
      token: 'demo-token',
      refreshToken: 'demo-refresh',
    );
    notifyListeners();
  }

  /// Register FCM token with the backend (non-blocking).
  void _registerPushToken() {
    Future.microtask(() async {
      try {
        await PushNotificationService.getAndRegisterToken();
      } catch (_) {
        // Non-critical — app works without push notifications
      }
    });
  }
}
