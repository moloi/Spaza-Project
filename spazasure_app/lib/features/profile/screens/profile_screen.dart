import 'package:flutter/material.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile'), backgroundColor: AppColors.surface),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.surface,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 44, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text('Thabo Molefe', style: AppTextStyles.h3),
                  Text("Thabo's Spaza Shop", style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 16, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text('Verified', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Quick stats
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _statItem('12', 'Orders'),
                  _divider(),
                  _statItem('R28.5K', 'Total Spent'),
                  _divider(),
                  _statItem('4', 'Suppliers'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Menu items
            _buildMenuSection('Account', [
              _menuItem(Icons.store_outlined, 'Shop Details', () {}),
              _menuItem(Icons.location_on_outlined, 'Delivery Address', () {}),
              _menuItem(Icons.account_balance_wallet_outlined, 'SpazaSure Wallet', () {}),
            ]),
            _buildMenuSection('Compliance', [
              _menuItem(Icons.description_outlined, 'My Documents', () => Navigator.pushNamed(context, '/compliance'), badge: '1 expiring'),
              _menuItem(Icons.verified_user_outlined, 'Verification Status', () {}),
            ]),
            _buildMenuSection('Settings', [
              _menuItem(Icons.notifications_outlined, 'Notifications', () {}),
              _menuItem(Icons.language, 'Language', () {}, trailing: 'English'),
              _menuItem(Icons.help_outline, 'Help & Support', () {}),
              _menuItem(Icons.info_outline, 'About SpazaSure', () {}),
            ]),
            const SizedBox(height: 12),
            // Logout
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text('Log Out', style: AppTextStyles.body.copyWith(color: AppColors.error)),
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
              ),
            ),
            const SizedBox(height: 32),
            Text('SpazaSure v1.0.0', style: AppTextStyles.caption),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.divider);

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {String? badge, String? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: AppTextStyles.body),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge, style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
            ),
          if (trailing != null)
            Text(trailing, style: AppTextStyles.bodySmall),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

