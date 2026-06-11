import 'api_service.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String priority;
  final bool isRead;
  final String? referenceId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.priority = 'normal',
    this.isRead = false,
    this.referenceId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'normal',
      isRead: json['isRead'] ?? false,
      referenceId: json['referenceId'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationService {
  /// Get all notifications for the current shop.
  static Future<List<AppNotification>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await ApiService.get(
        '/shop/notifications?page=$page&pageSize=$pageSize');
    final data = res['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  /// Get unread notification count.
  static Future<int> getUnreadCount() async {
    final res = await ApiService.get('/shop/notifications/unread-count');
    final data = res['data'] as Map<String, dynamic>;
    return data['count'] as int? ?? 0;
  }

  /// Mark a single notification as read.
  static Future<void> markAsRead(String id) async {
    await ApiService.patch('/shop/notifications/$id/read', {});
  }

  /// Mark all notifications as read.
  static Future<void> markAllAsRead() async {
    await ApiService.patch('/shop/notifications/read-all', {});
  }
}
