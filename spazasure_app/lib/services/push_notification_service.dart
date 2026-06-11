import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Handles background messages when the app is not in the foreground.
/// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message (e.g., update badge count)
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'spazasure_high',
    'SpazaSure Notifications',
    description: 'Important notifications from SpazaSure',
    importance: Importance.high,
  );

  /// Initialize push notifications. Call this once at app startup after Firebase.initializeApp().
  static Future<void> initialize() async {
    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS/web)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User denied push permissions
    }

    // Set up local notifications for foreground display
    await _setupLocalNotifications();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Get the FCM token and register it with the backend.
  static Future<String?> getAndRegisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerTokenWithBackend(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_registerTokenWithBackend);

      return token;
    } catch (_) {
      return null;
    }
  }

  /// Register the FCM token with the backend so it can send targeted push notifications.
  static Future<void> _registerTokenWithBackend(String fcmToken) async {
    try {
      await ApiService.post('/shop/notifications/register-device', {
        'fcmToken': fcmToken,
        'platform': _getPlatform(),
      });
    } catch (_) {
      // Non-critical — silently fail if backend is unavailable
    }
  }

  static String _getPlatform() {
    // Simplified platform detection
    return 'mobile';
  }

  /// Set up local notification display for when the app is in the foreground.
  static Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap from local notification
        _onLocalNotificationTap(details);
      },
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  /// Display a local notification when a push is received in the foreground.
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['referenceId'],
    );
  }

  /// Handle when user taps a notification that opened the app from background.
  static void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on message data
    final type = message.data['type'];
    final referenceId = message.data['referenceId'];

    // The app's router should handle navigation based on notification type.
    // This can be connected to a global navigator key or a notification stream.
    _notificationTapCallback?.call(type, referenceId);
  }

  static void _onLocalNotificationTap(NotificationResponse details) {
    // Handle local notification tap — payload contains the referenceId
    _notificationTapCallback?.call(null, details.payload);
  }

  // Callback for notification taps — set this from the app's main widget
  static void Function(String? type, String? referenceId)? _notificationTapCallback;

  /// Set a callback to handle notification taps for navigation.
  static void setOnNotificationTap(
      void Function(String? type, String? referenceId) callback) {
    _notificationTapCallback = callback;
  }

  /// Unsubscribe from push notifications (e.g., on logout).
  static Future<void> unregister() async {
    await _messaging.deleteToken();
  }
}
