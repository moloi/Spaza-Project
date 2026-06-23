import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // QA server URL — all API calls go to the deployed backend
  static const _qaUrl = 'http://167.233.69.205/api';

  static String get baseUrl {
    // Always use the QA server for now
    return _qaUrl;
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  static Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));
      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to connect to server', 0);
    }
  }

  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body['message'] ?? body['error'] ?? 'Something went wrong';
    throw ApiException(msg.toString(), res.statusCode);
  }

  /// Upload a file using multipart form data
  static Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String fieldName,
    required List<int> fileBytes,
    required String fileName,
    Map<String, String>? fields,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri);

      // Add auth header
      final token = await _getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      // Add file
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
      ));

      // Add extra fields
      if (fields != null) request.fields.addAll(fields);

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Upload failed: $e', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
