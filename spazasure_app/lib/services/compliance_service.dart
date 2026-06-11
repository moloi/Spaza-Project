import 'api_service.dart';

class ComplianceDocument {
  final String id;
  final String docType;
  final String? docUrl;
  final String status;
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
      id: json['id'].toString(),
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

  /// Upload a compliance document.
  /// Note: For file uploads, use multipart — this method prepares the request
  /// but actual file upload requires http.MultipartRequest.
  static Future<void> uploadDocument({
    required String docType,
    required String filePath,
  }) async {
    // For file uploads, we need to use multipart form data.
    // This is a placeholder — the actual implementation should use
    // http.MultipartRequest pointed at the gateway URL.
    await ApiService.post('/shop/compliance/documents', {
      'docType': docType,
      'filePath': filePath,
    });
  }
}
