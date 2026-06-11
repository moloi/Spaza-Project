import 'api_service.dart';

class ShopProfile {
  final String id;
  final String shopName;
  final String ownerName;
  final String phone;
  final String? email;
  final String address;
  final String? city;
  final String? province;
  final String? postalCode;
  final String status;
  final String complianceStatus;
  final double ratingAvg;
  final int ratingCount;
  final double? latitude;
  final double? longitude;

  ShopProfile({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    this.email,
    required this.address,
    this.city,
    this.province,
    this.postalCode,
    required this.status,
    required this.complianceStatus,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.latitude,
    this.longitude,
  });

  factory ShopProfile.fromJson(Map<String, dynamic> json) {
    return ShopProfile(
      id: json['id'].toString(),
      shopName: json['shopName'] ?? '',
      ownerName: json['ownerName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'] ?? '',
      city: json['city'],
      province: json['province'],
      postalCode: json['postalCode'],
      status: json['status'] ?? 'pending',
      complianceStatus: json['complianceStatus'] ?? 'incomplete',
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class ProfileService {
  /// Get the current shop's profile.
  static Future<ShopProfile> getProfile() async {
    final res = await ApiService.get('/shop/profile');
    final data = res['data'] as Map<String, dynamic>;
    return ShopProfile.fromJson(data);
  }

  /// Update the shop profile.
  static Future<void> updateProfile({
    String? shopName,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? province,
    String? postalCode,
  }) async {
    await ApiService.put('/shop/profile', {
      if (shopName != null) 'shopName': shopName,
      if (ownerName != null) 'ownerName': ownerName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (province != null) 'province': province,
      if (postalCode != null) 'postalCode': postalCode,
    });
  }
}
