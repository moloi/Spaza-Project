import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/providers/auth_provider.dart';
import 'package:spazasure_app/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ShopProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await ProfileService.getProfile();
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ownerName = _profile?.ownerName ?? auth.session?.fullName ?? '';
    final shopName = _profile?.shopName ?? auth.session?.shopName ?? 'My Spaza Shop';
    final phone = _profile?.phone ?? auth.session?.phone ?? '';
    final email = _profile?.email ?? '';
    final address = _profile?.address ?? '';
    final city = _profile?.city ?? '';
    final province = _profile?.province ?? '';
    final status = _profile?.status ?? 'pending';
    final complianceStatus = _profile?.complianceStatus ?? 'incomplete';
    final ratingAvg = _profile?.ratingAvg ?? 0.0;
    final ratingCount = _profile?.ratingCount ?? 0;
    final onboardingFeePaid = _profile?.onboardingFeePaid ?? false;

    final displayName = ownerName.isNotEmpty ? ownerName : shopName;
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'SP';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadProfile, tooltip: 'Refresh'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: AppColors.warning.withOpacity(0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off, size: 18, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Showing cached data. Pull to refresh.', style: AppTextStyles.caption.copyWith(color: AppColors.warning))),
                          ],
                        ),
                      ),

                    // Profile header
                    Container(
                      padding: const EdgeInsets.all(24),
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: Center(child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary))),
                          ),
                          const SizedBox(height: 12),
                          if (ownerName.isNotEmpty) Text(ownerName, style: AppTextStyles.h3),
                          Text(shopName, style: ownerName.isNotEmpty ? AppTextStyles.bodySmall : AppTextStyles.h3),
                          if (phone.isNotEmpty) ...[const SizedBox(height: 4), Text(phone, style: AppTextStyles.bodySmall)],
                          if (email.isNotEmpty) ...[const SizedBox(height: 2), Text(email, style: AppTextStyles.caption)],
                          const SizedBox(height: 8),
                          _statusBadge(status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          _statItem(ratingAvg > 0 ? '${ratingAvg.toStringAsFixed(1)}★' : '-', 'Rating'),
                          _divider(),
                          _statItem(_complianceLabel(complianceStatus), 'Compliance'),
                          _divider(),
                          _statItem(onboardingFeePaid ? '✓ Paid' : 'Pending', 'Onboarding'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Shop location
                    if (address.isNotEmpty || city.isNotEmpty)
                      _buildInfoSection('Shop Location', [
                        if (address.isNotEmpty) _infoRow(Icons.location_on_outlined, address),
                        if (city.isNotEmpty || province.isNotEmpty)
                          _infoRow(Icons.map_outlined, [city, province].where((s) => s.isNotEmpty).join(', ')),
                      ]),

                    // Account
                    _buildMenuSection('Account', [
                      _menuItem(Icons.store_outlined, 'Shop Details', () => _showShopDetails(context, shopName, ownerName, phone, email, address, city, province)),
                      _menuItem(Icons.account_balance_wallet_outlined, 'SpazaSure Wallet', () => Navigator.pushNamed(context, '/wallet')),
                    ]),

                    // Compliance
                    _buildMenuSection('Compliance', [
                      _menuItem(Icons.description_outlined, 'My Documents', () => Navigator.pushNamed(context, '/compliance')),
                      _menuItem(Icons.verified_user_outlined, 'Verification Status', () => _showVerificationStatus(context, status, complianceStatus, onboardingFeePaid)),
                    ]),

                    // Settings
                    _buildMenuSection('App', [
                      _menuItem(Icons.notifications_outlined, 'Notifications', () => Navigator.pushNamed(context, '/notifications')),
                      _menuItem(Icons.help_outline, 'Help & Support', () => _showHelpSupport(context)),
                      _menuItem(Icons.info_outline, 'About SpazaSure', () => _showAbout(context)),
                    ]),
                    const SizedBox(height: 12),

                    // Logout
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: AppColors.error),
                        title: Text('Log Out', style: AppTextStyles.body.copyWith(color: AppColors.error)),
                        onTap: () async {
                          await context.read<AuthProvider>().logout();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('SpazaSure v1.0.0', style: AppTextStyles.caption),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Shop Details Bottom Sheet ──
  void _showShopDetails(BuildContext context, String shopName, String ownerName, String phone, String email, String address, String city, String province) {
    final shopCtrl = TextEditingController(text: shopName);
    final ownerCtrl = TextEditingController(text: ownerName);
    final phoneCtrl = TextEditingController(text: phone);
    final emailCtrl = TextEditingController(text: email);
    final addressCtrl = TextEditingController(text: address);
    final cityCtrl = TextEditingController(text: city);
    final provinceCtrl = TextEditingController(text: province);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text('Shop Details', style: AppTextStyles.h3),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        try {
                          await ProfileService.updateProfile({
                            'shopName': shopCtrl.text,
                            'ownerName': ownerCtrl.text,
                            'phone': phoneCtrl.text,
                            'email': emailCtrl.text,
                            'address': addressCtrl.text,
                            'city': cityCtrl.text,
                            'province': provinceCtrl.text,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadProfile();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('Profile updated'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ));
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ));
                          }
                        }
                      },
                      child: Text('Save', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _editField('Shop Name', shopCtrl, Icons.store_outlined),
                    _editField('Owner Name', ownerCtrl, Icons.person_outline),
                    _editField('Phone', phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                    _editField('Email', emailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
                    _editField('Address', addressCtrl, Icons.location_on_outlined),
                    _editField('City', cityCtrl, Icons.location_city_outlined),
                    _editField('Province', provinceCtrl, Icons.map_outlined),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }

  // ── Verification Status Bottom Sheet ──
  void _showVerificationStatus(BuildContext context, String status, String complianceStatus, bool feePaid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Verification Status', style: AppTextStyles.h3),
            const SizedBox(height: 24),
            _verifyRow('Account Status', status == 'verified' ? 'Verified' : 'Pending', status == 'verified' ? AppColors.success : AppColors.warning, status == 'verified' ? Icons.check_circle : Icons.hourglass_top),
            const SizedBox(height: 12),
            _verifyRow('Compliance', _complianceLabel(complianceStatus), complianceStatus == 'green' ? AppColors.success : AppColors.warning, complianceStatus == 'green' ? Icons.check_circle : Icons.warning_amber),
            const SizedBox(height: 12),
            _verifyRow('Onboarding Fee', feePaid ? 'Paid' : 'Not Paid', feePaid ? AppColors.success : AppColors.error, feePaid ? Icons.check_circle : Icons.cancel),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Upload all required documents and pay the onboarding fee to get fully verified.', style: AppTextStyles.caption.copyWith(color: AppColors.info))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifyRow(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Help & Support ──
  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Help & Support', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            _supportItem(Icons.email_outlined, 'Email Support', 'support@spazasure.co.za'),
            const SizedBox(height: 10),
            _supportItem(Icons.phone_outlined, 'Call Us', '0800 123 456'),
            const SizedBox(height: 10),
            _supportItem(Icons.chat_outlined, 'WhatsApp', '+27 60 123 4567'),
            const SizedBox(height: 10),
            _supportItem(Icons.access_time_outlined, 'Hours', 'Mon-Fri 8am-5pm'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ── About ──
  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('SpazaSure', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: AppTextStyles.caption),
            const SizedBox(height: 16),
            Text(
              'SpazaSure connects spaza shop owners with verified suppliers, '
              'ensuring safe, affordable products reach communities across South Africa.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _aboutRow('Platform', 'Flutter & .NET 9'),
                  _aboutRow('Database', 'PostgreSQL'),
                  _aboutRow('Built by', 'SpazaSure Team'),
                  _aboutRow('Year', '2026'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Shared widgets ──
  Widget _statusBadge(String status) {
    final isVerified = status == 'verified';
    final color = isVerified ? AppColors.success : AppColors.warning;
    final label = isVerified ? 'Verified' : 'Pending Verification';
    final icon = isVerified ? Icons.verified : Icons.pending_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600))],
      ),
    );
  }

  String _complianceLabel(String status) {
    switch (status) {
      case 'green': return '✓ Good';
      case 'orange': return '⚠ Review';
      case 'red': return '✗ Action';
      default: return 'Incomplete';
    }
  }

  Widget _statItem(String value, String label) => Expanded(
    child: Column(children: [
      Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontSize: 14)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ]),
  );

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.divider);

  Widget _buildInfoSection(String title, List<Widget> items) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      ...items,
    ]),
  );

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [Icon(icon, size: 18, color: AppColors.textSecondary), const SizedBox(width: 10), Expanded(child: Text(text, style: AppTextStyles.body))]),
  );

  Widget _buildMenuSection(String title, List<Widget> items) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5))),
      ...items,
    ]),
  );

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: AppColors.textSecondary, size: 22),
    title: Text(title, style: AppTextStyles.body),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
    onTap: onTap,
  );
}
