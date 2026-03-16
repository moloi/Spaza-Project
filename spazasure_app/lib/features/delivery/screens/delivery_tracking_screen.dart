import 'package:flutter/material.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/models/models.dart';

class DeliveryTrackingScreen extends StatelessWidget {
  const DeliveryTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Track ${order.orderNumber}'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Map placeholder
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('Live Map View', style: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondary)),
                        Text('Google Maps integration', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  // Driver marker
                  Positioned(
                    top: 100,
                    left: 150,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
                    ),
                  ),
                  // Shop marker
                  Positioned(
                    bottom: 80,
                    right: 100,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Driver info card
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  // ETA
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Text('Estimated arrival in ', style: AppTextStyles.body),
                        Text('25 minutes', style: AppTextStyles.subtitle.copyWith(color: AppColors.info)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Driver info
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('John Mokoena', style: AppTextStyles.subtitle),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text('4.8', style: AppTextStyles.bodySmall),
                                Text(' • Delivery Driver', style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone, color: AppColors.success),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.message, color: AppColors.info),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Status updates
                  Row(
                    children: [
                      _statusDot(true),
                      const SizedBox(width: 8),
                      Text('Order picked up', style: AppTextStyles.bodySmall),
                      const Spacer(),
                      Text('10:30 AM', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statusDot(true),
                      const SizedBox(width: 8),
                      Text('In transit to your shop', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('10:45 AM', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(bool active) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? AppColors.success : AppColors.divider,
        shape: BoxShape.circle,
      ),
    );
  }
}

