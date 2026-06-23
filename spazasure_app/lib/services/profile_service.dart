import 'api_service.dart';

class ShopProfile {
  final String id;
  final String shopName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String province;
  final String status;
  final String complianceStatus;
  final bool onboardingFeePaid;
  final double ratingAvg;
  final int ratingCount;
  final String joinedAt;

  ShopProfile({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.province,
    required this.status,
    required this.complianceStatus,
    required this.onboardingFeePaid,
    required this.ratingAvg,
    required this.ratingCount,
    required this.joinedAt,
  });

  factory ShopProfile.fromJson(Map<String, dynamic> json) {
    return ShopProfile(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName'] ?? '',
      ownerName: json['ownerName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      status: json['status'] ?? 'pending',
      complianceStatus: json['complianceStatus'] ?? 'incomplete',
      onboardingFeePaid: json['onboardingFeePaid'] ?? false,
      ratingAvg: (json['ratingAvg'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      joinedAt: json['joinedAt'] ?? '',
    );
  }
}

class ProfileService {
  static Future<ShopProfile> getProfile() async {
    final res = await ApiService.get('/shop/profile');
    return ShopProfile.fromJson(res['data'] as Map<String, dynamic>);
  }

  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    await ApiService.patch('/shop/profile', updates);
  }
}
