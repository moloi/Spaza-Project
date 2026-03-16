import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/core/widgets/status_badge.dart';
import 'package:spazasure_app/services/mock_data.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = MockData.orders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders'), backgroundColor: AppColors.surface),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.orderNumber, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
                      StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(order.supplierName, style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt), style: AppTextStyles.caption),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${order.items.length} item${order.items.length > 1 ? 's' : ''}', style: AppTextStyles.bodySmall),
                      Text('R${order.total.toStringAsFixed(2)}', style: AppTextStyles.price),
                    ],
                  ),
                  if (order.status == 'dispatched' && order.estimatedDelivery != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping, size: 16, color: AppColors.info),
                          const SizedBox(width: 6),
                          Text(
                            'ETA: ${DateFormat('HH:mm').format(order.estimatedDelivery!)}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.info, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

