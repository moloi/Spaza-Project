import 'api_service.dart';

class VerificationResult {
  final bool verified;
  final bool expired;
  final bool recalled;
  final String message;
  final ProductInfo? product;
  final SupplierInfo? supplier;
  final bool previouslyScanned;

  VerificationResult({
    required this.verified,
    this.expired = false,
    this.recalled = false,
    required this.message,
    this.product,
    this.supplier,
    this.previouslyScanned = false,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      verified: json['verified'] ?? false,
      expired: json['expired'] ?? false,
      recalled: json['recalled'] ?? false,
      message: json['message'] ?? '',
      product: json['product'] != null
          ? ProductInfo.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      supplier: json['supplier'] != null
          ? SupplierInfo.fromJson(json['supplier'] as Map<String, dynamic>)
          : null,
      previouslyScanned: json['scan']?['previouslyScanned'] ?? false,
    );
  }
}

class ProductInfo {
  final String name;
  final String? description;
  final String sku;
  final double price;
  final String? category;
  final String? batchNumber;
  final String? expiryDate;
  final bool isFoodItem;

  ProductInfo({
    required this.name,
    this.description,
    required this.sku,
    required this.price,
    this.category,
    this.batchNumber,
    this.expiryDate,
    this.isFoodItem = false,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      name: json['name'] ?? '',
      description: json['description'],
      sku: json['sku'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'],
      batchNumber: json['batchNumber'],
      expiryDate: json['expiryDate'],
      isFoodItem: json['isFoodItem'] ?? false,
    );
  }
}

class SupplierInfo {
  final String companyName;
  final String phone;
  final String email;
  final String tier;

  SupplierInfo({
    required this.companyName,
    required this.phone,
    required this.email,
    required this.tier,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      companyName: json['companyName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      tier: json['tier'] ?? '',
    );
  }
}

class VerificationService {
  /// Verify a product by scanning its QR code.
  /// Calls GET /api/verify/{qrCode} via the gateway.
  static Future<VerificationResult> verifyProduct(String qrCode) async {
    try {
      final res = await ApiService.get('/verify/$qrCode');
      final data = res['data'] as Map<String, dynamic>;
      return VerificationResult.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return VerificationResult(
          verified: false,
          message: 'Product not found. This may be a counterfeit item.',
        );
      }
      rethrow;
    }
  }

  /// Report a suspected counterfeit product.
  /// Calls POST /api/verify/report via the gateway.
  static Future<void> reportCounterfeit({
    String? qrCode,
    String? description,
    String? location,
  }) async {
    await ApiService.post('/verify/report', {
      if (qrCode != null) 'qrCode': qrCode,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
    });
  }

  /// Get scan history for the current shop.
  /// Calls GET /api/verify/history via the gateway.
  static Future<Map<String, dynamic>> getScanHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await ApiService.get('/verify/history?page=$page&pageSize=$pageSize');
    return res['data'] as Map<String, dynamic>;
  }
}
