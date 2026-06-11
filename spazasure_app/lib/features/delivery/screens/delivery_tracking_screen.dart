import 'package:flutter/material.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/models/models.dart';
import 'package:spazasure_app/services/delivery_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  DeliveryStatus? _delivery;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDeliveryStatus();
  }

  Future<void> _loadDeliveryStatus() async {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    try {
      final status = await DeliveryService.getDeliveryStatus(order.id);
      if (mounted) setState(() { _delivery = status; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _confirmDelivery() async {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    try {
      await DeliveryService.confirmDelivery(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Delivery confirmed! Thank you.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    final displayName = _delivery?.orderNumber ?? order.orderNumber;
    final stage = _delivery?.deliveryStage ?? _stageFromStatus(order.status);
    final supplierName = _delivery?.supplierName ?? order.supplierName;
    final supplierPhone = _delivery?.supplierPhone ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Track $displayName'),
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
                  if (stage == 'in_transit')
                    Positioned(
                      top: 100,
                      left: 150,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
                      ),
                    ),
                  // Shop marker
                  Positioned(
                    bottom: 80,
                    right: 100,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 16),
                        // ETA
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _stageColor(stage).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_stageIcon(stage), color: _stageColor(stage), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _stageLabel(stage),
                                  style: AppTextStyles.subtitle.copyWith(color: _stageColor(stage)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Supplier info
                        Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.store, color: AppColors.primary, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(supplierName, style: AppTextStyles.subtitle),
                                  if (supplierPhone.isNotEmpty)
                                    Text(supplierPhone, style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            if (supplierPhone.isNotEmpty)
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.phone, color: AppColors.success),
                              ),
                          ],
                        ),
                        const Spacer(),
                        // Delivery progress steps
                        _buildProgressSteps(stage),
                        const SizedBox(height: 12),
                        // Confirm button (only if dispatched)
                        if (stage == 'in_transit')
                          SizedBox(
                            width: double.infinity, height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _confirmDelivery,
                              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                              label: Text('Confirm Delivery Received', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(String stage) {
    final steps = ['awaiting_confirmation', 'preparing', 'in_transit', 'delivered'];
    final currentIdx = steps.indexOf(stage).clamp(0, steps.length - 1);
    final labels = ['Confirmed', 'Preparing', 'In Transit', 'Delivered'];

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentIdx;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0) Expanded(child: Container(height: 2, color: isActive ? AppColors.success : AppColors.divider)),
                  Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: isActive ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                  ),
                  if (i < steps.length - 1) Expanded(child: Container(height: 2, color: i < currentIdx ? AppColors.success : AppColors.divider)),
                ],
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: AppTextStyles.caption.copyWith(color: isActive ? AppColors.success : AppColors.textHint, fontSize: 10)),
            ],
          ),
        );
      }),
    );
  }

  String _stageFromStatus(String status) {
    return switch (status) {
      'pending' => 'awaiting_confirmation',
      'processing' => 'preparing',
      'dispatched' => 'in_transit',
      'delivered' => 'delivered',
      _ => 'awaiting_confirmation',
    };
  }

  Color _stageColor(String stage) => switch (stage) {
    'in_transit' => AppColors.info,
    'delivered' => AppColors.success,
    'preparing' => AppColors.warning,
    _ => AppColors.textSecondary,
  };

  IconData _stageIcon(String stage) => switch (stage) {
    'in_transit' => Icons.local_shipping,
    'delivered' => Icons.check_circle,
    'preparing' => Icons.inventory_2_outlined,
    _ => Icons.access_time,
  };

  String _stageLabel(String stage) => switch (stage) {
    'awaiting_confirmation' => 'Awaiting supplier confirmation',
    'preparing' => 'Order is being prepared',
    'in_transit' => 'Your order is on its way!',
    'delivered' => 'Delivery complete',
    'cancelled' => 'Order cancelled',
    _ => 'Processing...',
  };
}
