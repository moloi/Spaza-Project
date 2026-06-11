import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

class ApiService {
  // Use environment-configured URL with platform fallback
  static String get baseUrl => AppConfig.apiBaseUrl;

  static bool _isRefreshing = false;

  // ── Token management ──────────────────────────────────────────────────────

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('shop_name');
    await prefs.remove('phone');
  }

  // ── Headers ───────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Token refresh ─────────────────────────────────────────────────────────

  /// Attempt to refresh the access token using the stored refresh token.
  /// Returns true if successful, false if the user needs to re-authenticate.
  static Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) return false; // Prevent concurrent refresh attempts
    _isRefreshing = true;

    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final res = await http
          .post(
            Uri.parse('$baseUrl/shop/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          await _saveTokens(
            data['accessToken'] as String,
            data['refreshToken'] as String,
          );
          return true;
        }
      }

      // Refresh failed — clear tokens so user is prompted to re-login
      await _clearTokens();
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ── HTTP methods with auto-retry on 401 ────────────────────────────────────

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      var res = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      // If 401, try refreshing the token and retry once
      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          res = await http
              .get(
                Uri.parse('$baseUrl$path'),
                headers: await _headers(),
              )
              .timeout(const Duration(seconds: 10));
        }
      }

      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      var res = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      // If 401 and this was an authenticated request, try refresh
      if (res.statusCode == 401 && auth) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          res = await http
              .post(
                Uri.parse('$baseUrl$path'),
                headers: await _headers(auth: auth),
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 10));
        }
      }

      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      var res = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          res = await http
              .put(
                Uri.parse('$baseUrl$path'),
                headers: await _headers(),
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 10));
        }
      }

      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      var res = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          res = await http
              .patch(
                Uri.parse('$baseUrl$path'),
                headers: await _headers(),
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 10));
        }
      }

      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      var res = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          res = await http
              .delete(
                Uri.parse('$baseUrl$path'),
                headers: await _headers(),
              )
              .timeout(const Duration(seconds: 10));
        }
      }

      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  // ── Response handling ─────────────────────────────────────────────────────

  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final msg = body['message'] ?? body['error'] ?? 'Something went wrong';

    // If still 401 after refresh attempt, signal session expired
    if (res.statusCode == 401) {
      throw SessionExpiredException(msg.toString());
    }

    throw ApiException(msg.toString(), res.statusCode);
  }
}

/// General API exception for non-2xx responses.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Thrown when the session is expired and cannot be refreshed.
/// The UI should catch this and redirect to the login screen.
class SessionExpiredException extends ApiException {
  SessionExpiredException(String message) : super(message, 401);
}
