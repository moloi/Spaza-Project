import 'api_service.dart';

class DeliveryStatus {
  final String orderId;
  final String orderNumber;
  final String status;
  final String deliveryStage;
  final String deliveryType;
  final String? deliveryAddress;
  final String? supplierName;
  final String? supplierPhone;
  final String? estimatedDelivery;
  final DateTime? updatedAt;

  DeliveryStatus({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.deliveryStage,
    required this.deliveryType,
    this.deliveryAddress,
    this.supplierName,
    this.supplierPhone,
    this.estimatedDelivery,
    this.updatedAt,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      orderId: json['orderId'].toString(),
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? '',
      deliveryStage: json['deliveryStage'] ?? '',
      deliveryType: json['deliveryType'] ?? 'standard',
      deliveryAddress: json['deliveryAddress'],
      supplierName: json['supplier']?['name'],
      supplierPhone: json['supplier']?['phone'],
      estimatedDelivery: json['estimatedDelivery'],
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

class DeliveryService {
  /// Get delivery status for a specific order.
  static Future<DeliveryStatus> getDeliveryStatus(String orderId) async {
    final res = await ApiService.get('/shop/delivery/$orderId');
    final data = res['data'] as Map<String, dynamic>;
    return DeliveryStatus.fromJson(data);
  }

  /// Get all active deliveries for the current shop.
  static Future<List<DeliveryStatus>> getActiveDeliveries() async {
    final res = await ApiService.get('/shop/delivery/active');
    final data = res['data'] as Map<String, dynamic>;
    final items = data['deliveries'] as List<dynamic>;
    return items.map((d) {
      final map = d as Map<String, dynamic>;
      return DeliveryStatus(
        orderId: map['orderId'].toString(),
        orderNumber: map['orderNumber'] ?? '',
        status: map['status'] ?? '',
        deliveryStage: map['status'] == 'dispatched' ? 'in_transit' : 'preparing',
        deliveryType: map['deliveryType'] ?? 'standard',
        supplierName: map['supplierName'],
        supplierPhone: map['supplierPhone'],
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'])
            : null,
      );
    }).toList();
  }

  /// Confirm delivery receipt.
  static Future<void> confirmDelivery(String orderId) async {
    await ApiService.post('/shop/delivery/$orderId/confirm', {});
  }

  /// Get delivery history.
  static Future<Map<String, dynamic>> getDeliveryHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await ApiService.get(
        '/shop/delivery/history?page=$page&pageSize=$pageSize');
    return res['data'] as Map<String, dynamic>;
  }
}
