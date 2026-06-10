import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';

class GroupBuyScreen extends StatefulWidget {
  const GroupBuyScreen({super.key});
  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const _activeGroups = [
    _Group('Cooking Oil - 100 units', 'Tiger Brands', 75, 100, 3, 'R54.99/unit', '15% off', 2),
    _Group('Maize Meal 10kg - 50 units', 'Pioneer Foods', 30, 50, 2, 'R89.99/unit', '10% off', 1),
    _Group('Coca-Cola 2L 6-Pack x 48', 'RCL Foods', 48, 48, 4, 'R89.99/pack', '20% off', 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Group Buying'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Active Groups'), Tab(text: 'My Groups')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroup(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Create Group', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildActiveGroups(),
          _buildMyGroups(),
        ],
      ),
    );
  }

  Widget _buildActiveGroups() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Save More Together', style: AppTextStyles.subtitle.copyWith(color: Colors.white)),
                    Text('Join a group to unlock bulk discounts\nand split delivery costs', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ..._activeGroups.asMap().entries.map((e) =>
          _GroupCard(group: e.value, onJoin: () => _showJoinGroup(context, e.value))
            .animate(delay: (100 * e.key).ms).fadeIn().slideY(begin: 0.1, end: 0),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMyGroups() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text("You haven't joined any groups yet", style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text('Join an active group or create your own', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  void _showJoinGroup(BuildContext context, _Group group) {
    final controller = TextEditingController(text: '10');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(left: 28, right: 28, top: 28, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Join Group Buy', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(group.productName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Text('${group.discount} when target is reached', style: AppTextStyles.body.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('How many units do you need?', style: AppTextStyles.subtitle),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity', suffixText: 'units'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Joined group! ${controller.text} units committed.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                },
                child: const Text('Confirm & Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(left: 28, right: 28, top: 28, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Create Group Buy', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.inventory_2_outlined))),
            const SizedBox(height: 14),
            const TextField(decoration: InputDecoration(labelText: 'Target Quantity', prefixIcon: Icon(Icons.numbers), suffixText: 'units'), keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            const TextField(decoration: InputDecoration(labelText: 'Your Quantity', prefixIcon: Icon(Icons.shopping_cart_outlined), suffixText: 'units'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Group buy created! Nearby shops will be notified.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                },
                child: const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group {
  final String productName, supplier, discount;
  final int current, target, shopCount, daysLeft;
  final String pricePerUnit;
  const _Group(this.productName, this.supplier, this.current, this.target, this.shopCount, this.pricePerUnit, this.discount, this.daysLeft);
}

class _GroupCard extends StatelessWidget {
  final _Group group;
  final VoidCallback onJoin;
  const _GroupCard({required this.group, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final progress = group.current / group.target;
    final isFull = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.productName, style: AppTextStyles.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(group.supplier, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(group.discount, style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${group.current}/${group.target} units', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              Text('${(progress * 100).round()}% filled', style: AppTextStyles.caption.copyWith(color: isFull ? AppColors.success : AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(isFull ? AppColors.success : AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _chip(Icons.people_outline, '${group.shopCount} shops joined'),
              const SizedBox(width: 8),
              _chip(Icons.attach_money, group.pricePerUnit),
              if (group.daysLeft > 0) ...[ const SizedBox(width: 8), _chip(Icons.timer_outlined, '${group.daysLeft}d left', color: AppColors.warning)],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton(
              onPressed: isFull ? null : onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull ? AppColors.success : AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isFull ? '✅ Target Reached — Ordering' : 'Join Group', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color color = AppColors.textSecondary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
