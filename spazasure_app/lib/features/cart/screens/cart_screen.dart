import 'package:flutter/material.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/core/widgets/custom_button.dart';
import 'package:spazasure_app/services/mock_data.dart';
import 'package:spazasure_app/models/models.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _cartItems;
  String _deliveryOption = 'standard';
  String _paymentMethod = 'eft';

  @override
  void initState() {
    super.initState();
    _cartItems = [
      CartItem(product: MockData.products[0], quantity: 10),
      CartItem(product: MockData.products[3], quantity: 4),
      CartItem(product: MockData.products[7], quantity: 2),
    ];
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get _deliveryFee => _deliveryOption == 'express' ? 250.0 : _deliveryOption == 'standard' ? 150.0 : 0.0;
  double get _platformFee => _subtotal * 0.03;
  double get _total => _subtotal + _deliveryFee + _platformFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Cart (${_cartItems.length})'),
        backgroundColor: AppColors.surface,
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _cartItems.clear()),
              child: Text('Clear', style: AppTextStyles.body.copyWith(color: AppColors.error)),
            ),
        ],
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Cart items
                  ..._cartItems.asMap().entries.map((entry) => _buildCartItem(entry.key, entry.value)),
                  const SizedBox(height: 12),
                  // Delivery option
                  _buildSection('Delivery Option', _buildDeliveryOptions()),
                  const SizedBox(height: 12),
                  // Payment method
                  _buildSection('Payment Method', _buildPaymentOptions()),
                  const SizedBox(height: 12),
                  // Order summary
                  _buildOrderSummary(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: 'Place Order  •  R${_total.toStringAsFixed(2)}',
                  onPressed: () => _showOrderConfirmation(),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Browse the marketplace to add products', style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Browse Products',
            width: 200,
            onPressed: () => Navigator.pushNamed(context, '/marketplace'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index, CartItem item) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.product.supplierName, style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('R${item.total.toStringAsFixed(2)}', style: AppTextStyles.priceSmall),
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _miniButton(Icons.remove, () {
                            if (item.quantity > 1) setState(() => item.quantity--);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('${item.quantity}', style: AppTextStyles.subtitle),
                          ),
                          _miniButton(Icons.add, () => setState(() => item.quantity++)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _cartItems.removeAt(index)),
            child: const Icon(Icons.close, size: 18, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    final options = [
      {'id': 'standard', 'title': 'Standard (2-3 days)', 'price': 'R150.00', 'icon': Icons.local_shipping_outlined},
      {'id': 'express', 'title': 'Express (Same day)', 'price': 'R250.00', 'icon': Icons.bolt},
      {'id': 'pickup', 'title': 'Pickup', 'price': 'Free', 'icon': Icons.store_outlined},
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = _deliveryOption == opt['id'];
        return GestureDetector(
          onTap: () => setState(() => _deliveryOption = opt['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(opt['icon'] as IconData, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(opt['title'] as String, style: AppTextStyles.body)),
                Text(opt['price'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                const SizedBox(width: 8),
                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.primary : AppColors.textHint, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentOptions() {
    final options = [
      {'id': 'eft', 'title': 'EFT / Bank Transfer', 'icon': Icons.account_balance_outlined},
      {'id': 'wallet', 'title': 'SpazaSure Wallet', 'icon': Icons.account_balance_wallet_outlined},
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = _paymentMethod == opt['id'];
        return GestureDetector(
          onTap: () => setState(() => _paymentMethod = opt['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(opt['icon'] as IconData, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(opt['title'] as String, style: AppTextStyles.body)),
                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.primary : AppColors.textHint, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', 'R${_subtotal.toStringAsFixed(2)}'),
          _summaryRow('Delivery Fee', 'R${_deliveryFee.toStringAsFixed(2)}'),
          _summaryRow('Platform Fee (3%)', 'R${_platformFee.toStringAsFixed(2)}'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.h3),
              Text('R${_total.toStringAsFixed(2)}', style: AppTextStyles.price),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }

  void _showOrderConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
            ),
            const SizedBox(height: 20),
            Text('Order Placed!', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text('SPZ-2025-0004', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(
              'Your order has been placed successfully. The supplier will be notified.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Track Order',
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: Text('Continue Shopping', style: AppTextStyles.body.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

