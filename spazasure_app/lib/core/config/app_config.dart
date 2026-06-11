import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized app configuration loaded from .env files.
/// Usage: AppConfig.apiBaseUrl
class AppConfig {
  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');

  static String get apiBaseUrl {
    final url = dotenv.get('API_BASE_URL', fallback: 'http://localhost:5181/api');

    // For Android emulator, rewrite localhost to 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && url.contains('localhost')) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  /// Load environment configuration. Call before runApp().
  static Future<void> load({String envFile = '.env'}) async {
    try {
      await dotenv.load(fileName: envFile);
    } catch (_) {
      // Fallback to defaults if .env not found
    }
  }
}
