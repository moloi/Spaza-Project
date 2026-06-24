import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/services/api_service.dart';
import 'package:spazasure_app/services/product_service.dart';
import 'package:spazasure_app/models/models.dart';

class GroupBuyScreen extends StatefulWidget {
  const GroupBuyScreen({super.key});

  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activeDeals = [];
  List<Map<String, dynamic>> _myDeals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final activeRes = await ApiService.get('/shop/group-buy?status=active');
      final myRes = await ApiService.get('/shop/group-buy?status=my');
      setState(() {
        _activeDeals = _parseList(activeRes['data']);
        _myDeals = _parseList(myRes['data']);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Group Buy'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Available Deals'),
            Tab(text: 'My Group Buys'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Group Buy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDealList(_activeDeals, showJoin: true),
                    _buildDealList(_myDeals, showJoin: false),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('Unable to load group buys', style: AppTextStyles.body),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildDealList(List<Map<String, dynamic>> deals, {required bool showJoin}) {
    if (deals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              showJoin ? 'No active group buys yet' : 'You haven\'t joined any group buys',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              showJoin ? 'Create one to start saving!' : 'Join a deal from the Available tab',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deals.length,
        itemBuilder: (context, index) {
          return _buildDealCard(deals[index], showJoin: showJoin)
              .animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }

  Widget _buildDealCard(Map<String, dynamic> deal, {required bool showJoin}) {
    final title = deal['title'] ?? 'Group Buy';
    final productName = deal['productName'] ?? '';
    final supplierName = deal['supplierName'] ?? '';
    final currentQty = deal['currentQty'] ?? 0;
    final targetQty = deal['targetQty'] ?? 1;
    final progress = targetQty > 0 ? (currentQty / targetQty).clamp(0.0, 1.0) : 0.0;
    final originalPrice = (deal['originalPrice'] as num?)?.toDouble() ?? 0;
    final discountPrice = (deal['discountPrice'] as num?)?.toDouble() ?? 0;
    final discountPct = deal['discountPct'] ?? 0;
    final participantCount = deal['participantCount'] ?? 0;
    final status = deal['status'] ?? 'active';
    final expiresAt = deal['expiresAt'] != null ? DateTime.tryParse(deal['expiresAt']) : null;
    final daysLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: status == 'completed'
                    ? [AppColors.success.withValues(alpha: 0.1), AppColors.success.withValues(alpha: 0.05)]
                    : [AppColors.accent.withValues(alpha: 0.1), AppColors.accent.withValues(alpha: 0.05)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(productName, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'completed' ? AppColors.success.withValues(alpha: 0.15) : AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status == 'completed' ? '✓ Complete' : '${daysLeft}d left',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: status == 'completed' ? AppColors.success : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price savings
                Row(
                  children: [
                    Text('R${originalPrice.toStringAsFixed(2)}', style: AppTextStyles.body.copyWith(decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                    const SizedBox(width: 8),
                    Text('R${discountPrice.toStringAsFixed(2)}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('-$discountPct%', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Supplier: $supplierName', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$currentQty / $targetQty units', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                              Text('${(progress * 100).toInt()}%', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.divider,
                              color: status == 'completed' ? AppColors.success : AppColors.primary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('$participantCount shops joined', style: AppTextStyles.caption),
                  ],
                ),
                // Join button
                if (showJoin && status == 'active') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _joinGroupBuy(deal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.group_add, size: 18),
                      label: const Text('Join Group Buy', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
                if (!showJoin && status == 'active') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveGroupBuy(deal),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.exit_to_app, size: 18),
                      label: const Text('Leave Group Buy', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinGroupBuy(Map<String, dynamic> deal) async {
    final minQty = deal['minOrderQty'] ?? 1;
    final qtyController = TextEditingController(text: '$minQty');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Join Group Buy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How many units do you want to commit?', style: AppTextStyles.body),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final qty = int.tryParse(qtyController.text) ?? 1;
      await ApiService.post('/shop/group-buy/${deal['id']}/join', {'quantity': qty});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('You joined the group buy!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _leaveGroupBuy(Map<String, dynamic> deal) async {
    try {
      await ApiService.post('/shop/group-buy/${deal['id']}/leave', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('You left the group buy'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _showCreateDialog() async {
    // First load products for user to pick from
    List<Product> products = [];
    try {
      products = await ProductService.getProducts(pageSize: 50);
    } catch (_) {}

    if (!mounted) return;

    Product? selectedProduct;
    final targetController = TextEditingController(text: '50');
    final myQtyController = TextEditingController(text: '5');
    final discountController = TextEditingController(text: '15');
    final daysController = TextEditingController(text: '7');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.groups_rounded, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text('Create Group Buy'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select a product to create a group buy for:', style: AppTextStyles.bodySmall),
                const SizedBox(height: 10),
                // Product dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<Product>(
                    value: selectedProduct,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: const Text('Choose product'),
                    items: products.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (R${p.price.toStringAsFixed(2)})', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (p) => setDialogState(() => selectedProduct = p),
                  ),
                ),
                const SizedBox(height: 14),
                _dialogField(targetController, 'Target Quantity (total units needed)', Icons.flag),
                const SizedBox(height: 10),
                _dialogField(myQtyController, 'My Commitment (units)', Icons.shopping_cart),
                const SizedBox(height: 10),
                _dialogField(discountController, 'Discount % (e.g. 15)', Icons.discount),
                const SizedBox(height: 10),
                _dialogField(daysController, 'Duration (days)', Icons.timer),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedProduct == null ? null : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (created != true || selectedProduct == null) return;

    try {
      await ApiService.post('/shop/group-buy', {
        'productId': selectedProduct!.id,
        'targetQty': int.tryParse(targetController.text) ?? 50,
        'myQty': int.tryParse(myQtyController.text) ?? 5,
        'discountPct': int.tryParse(discountController.text) ?? 15,
        'durationDays': int.tryParse(daysController.text) ?? 7,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Group buy created successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
