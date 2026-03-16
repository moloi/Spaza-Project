import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/services/mock_data.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = MockData.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No notifications', style: AppTextStyles.subtitle),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final icons = {
                  'order': Icons.receipt_long,
                  'delivery': Icons.local_shipping,
                  'compliance': Icons.verified_user,
                  'system': Icons.info_outline,
                };
                final colors = {
                  'order': AppColors.info,
                  'delivery': AppColors.accent,
                  'compliance': AppColors.warning,
                  'system': AppColors.textSecondary,
                };

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: notif.isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: notif.isRead ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (colors[notif.type] ?? AppColors.textSecondary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icons[notif.type] ?? Icons.notifications,
                          color: colors[notif.type] ?? AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif.title, style: AppTextStyles.subtitle.copyWith(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(notif.body, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(_timeAgo(notif.createdAt), style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(date);
  }
}

