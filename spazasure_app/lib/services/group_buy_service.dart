import 'api_service.dart';

class GroupBuy {
  final String id;
  final String title;
  final String status; // open, closed, completed
  final String initiatorShopName;
  final int participantCount;
  final int maxParticipants;
  final double targetAmount;
  final double currentAmount;
  final DateTime createdAt;
  final DateTime? closesAt;

  GroupBuy({
    required this.id,
    required this.title,
    required this.status,
    required this.initiatorShopName,
    required this.participantCount,
    required this.maxParticipants,
    required this.targetAmount,
    required this.currentAmount,
    required this.createdAt,
    this.closesAt,
  });

  factory GroupBuy.fromJson(Map<String, dynamic> json) {
    return GroupBuy(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      status: json['status'] ?? 'open',
      initiatorShopName: json['initiatorShopName'] ?? '',
      participantCount: json['participantCount'] ?? 0,
      maxParticipants: json['maxParticipants'] ?? 10,
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      closesAt: json['closesAt'] != null
          ? DateTime.tryParse(json['closesAt'])
          : null,
    );
  }
}

class GroupBuyService {
  /// Create a new group buy.
  static Future<GroupBuy> create({
    required String title,
    required List<Map<String, dynamic>> items,
    int maxParticipants = 10,
    DateTime? closesAt,
  }) async {
    final res = await ApiService.post('/shop/group-buy/create', {
      'title': title,
      'items': items,
      'maxParticipants': maxParticipants,
      if (closesAt != null) 'closesAt': closesAt.toIso8601String(),
    });
    final data = res['data'] as Map<String, dynamic>;
    return GroupBuy.fromJson(data);
  }

  /// Get nearby open group buys.
  static Future<List<GroupBuy>> getNearby() async {
    final res = await ApiService.get('/shop/group-buy/nearby');
    final data = res['data'] as List<dynamic>;
    return data
        .map((g) => GroupBuy.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  /// Join an existing group buy.
  static Future<void> join(String groupBuyId) async {
    await ApiService.post('/shop/group-buy/$groupBuyId/join', {});
  }

  /// Get details of a specific group buy.
  static Future<GroupBuy> getDetails(String groupBuyId) async {
    final res = await ApiService.get('/shop/group-buy/$groupBuyId');
    final data = res['data'] as Map<String, dynamic>;
    return GroupBuy.fromJson(data);
  }

  /// Get group buys the current shop is participating in.
  static Future<List<GroupBuy>> getMyGroupBuys() async {
    final res = await ApiService.get('/shop/group-buy/mine');
    final data = res['data'] as List<dynamic>;
    return data
        .map((g) => GroupBuy.fromJson(g as Map<String, dynamic>))
        .toList();
  }
}
