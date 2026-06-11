import 'package:flutter/material.dart';
import '../services/compliance_service.dart';

class ComplianceProvider extends ChangeNotifier {
  ComplianceStatus? _status;
  List<ComplianceDocument> _documents = [];
  bool _isLoading = false;
  String? _error;
  String? _uploadingDocType;

  ComplianceStatus? get status => _status;
  List<ComplianceDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get uploadingDocType => _uploadingDocType;

  /// Load compliance status and documents from backend.
  Future<void> loadStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _status = await ComplianceService.getStatus();
      _documents = _status!.documents;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload a document for a specific doc type.
  Future<bool> uploadDocument({
    required String docType,
    required String filePath,
  }) async {
    _uploadingDocType = docType;
    _error = null;
    notifyListeners();

    try {
      await ComplianceService.uploadDocument(
        docType: docType,
        filePath: filePath,
      );
      // Reload status after successful upload
      await loadStatus();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _uploadingDocType = null;
      notifyListeners();
    }
  }

  /// Get document by type (for checking individual doc status).
  ComplianceDocument? getDocByType(String docType) {
    try {
      return _documents.firstWhere((d) => d.docType == docType);
    } catch (_) {
      return null;
    }
  }
}
