import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import 'api_service.dart';

class ComplianceDocument {
  final String id;
  final String docType;
  final String? docUrl;
  final String status; // missing, pending, approved, rejected
  final String? expiryDate;
  final String? rejectionNote;
  final String? guidanceUrl;

  ComplianceDocument({
    required this.id,
    required this.docType,
    this.docUrl,
    required this.status,
    this.expiryDate,
    this.rejectionNote,
    this.guidanceUrl,
  });

  factory ComplianceDocument.fromJson(Map<String, dynamic> json) {
    return ComplianceDocument(
      id: json['id']?.toString() ?? '',
      docType: json['docType'] ?? '',
      docUrl: json['docUrl'],
      status: json['status'] ?? 'missing',
      expiryDate: json['expiryDate'],
      rejectionNote: json['rejectionNote'],
      guidanceUrl: json['guidanceUrl'],
    );
  }
}

class ComplianceStatus {
  final String overallStatus; // green, orange, red
  final List<ComplianceDocument> documents;
  final int totalRequired;
  final int approved;
  final int pending;
  final int missing;

  ComplianceStatus({
    required this.overallStatus,
    required this.documents,
    required this.totalRequired,
    required this.approved,
    required this.pending,
    required this.missing,
  });

  factory ComplianceStatus.fromJson(Map<String, dynamic> data) {
    final docs = (data['documents'] as List<dynamic>? ?? [])
        .map((d) => ComplianceDocument.fromJson(d as Map<String, dynamic>))
        .toList();
    return ComplianceStatus(
      overallStatus: data['overallStatus'] ?? 'red',
      documents: docs,
      totalRequired: data['totalRequired'] ?? 0,
      approved: data['approved'] ?? 0,
      pending: data['pending'] ?? 0,
      missing: data['missing'] ?? 0,
    );
  }
}

class ComplianceService {
  /// Get all compliance documents for the current shop.
  static Future<List<ComplianceDocument>> getDocuments() async {
    final res = await ApiService.get('/shop/compliance/documents');
    final data = res['data'] as Map<String, dynamic>;
    final docs = data['documents'] as List<dynamic>? ?? [];
    return docs
        .map((d) => ComplianceDocument.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  /// Get overall compliance status.
  static Future<ComplianceStatus> getStatus() async {
    final res = await ApiService.get('/shop/compliance/status');
    final data = res['data'] as Map<String, dynamic>;
    return ComplianceStatus.fromJson(data);
  }

  /// Upload a compliance document using multipart form data.
  static Future<ComplianceDocument> uploadDocument({
    required String docType,
    required String filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/shop/compliance/documents');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['docType'] = docType;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return ComplianceDocument(
        id: data['id']?.toString() ?? '',
        docType: data['docType'] ?? docType,
        docUrl: data['docUrl'],
        status: data['status'] ?? 'pending',
      );
    } else if (response.statusCode == 401) {
      throw SessionExpiredException('Session expired. Please log in again.');
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        body['message']?.toString() ?? 'Upload failed',
        response.statusCode,
      );
    }
  }
}
