import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletBalance? _balance;
  List<WalletTransaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        WalletService.getBalance(),
        WalletService.getTransactions(),
      ]);
      if (mounted) {
        setState(() {
          _balance = results[0] as WalletBalance;
          _transactions = results[1] as List<WalletTransaction>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceDisplay = _balance != null
        ? 'R ${_balance!.balance.toStringAsFixed(2)}'
        : 'R 0.00';
    final totalSpent = _balance?.totalSpent ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    title: Text('SpazaSure Wallet', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0D3B0F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(right: -30, top: -30, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
                            Positioned(left: -20, bottom: -20, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)))),
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Available Balance', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(balanceDisplay, style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text('Active', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _ActionButton(icon: Icons.add_rounded, label: 'Top Up', color: AppColors.primary, onTap: () => _showTopUp(context))),
                              const SizedBox(width: 12),
                              Expanded(child: _ActionButton(icon: Icons.send_rounded, label: 'Pay Order', color: AppColors.secondary, onTap: () {})),
                              const SizedBox(width: 12),
                              Expanded(child: _ActionButton(icon: Icons.history_rounded, label: 'History', color: AppColors.accent, onTap: () {})),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, delay: 200.ms),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _StatCard('R${_balance?.balance.toStringAsFixed(0) ?? '0'}', 'Balance', AppColors.success, Icons.account_balance_wallet_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: _StatCard('R${totalSpent.toStringAsFixed(0)}', 'Total Spent', AppColors.error, Icons.arrow_upward_rounded)),
                            ],
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 24),
                          Text('Recent Transactions', style: AppTextStyles.h3),
                          const SizedBox(height: 12),
                          if (_transactions.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text('No transactions yet', style: AppTextStyles.bodySmall),
                              ),
                            )
                          else
                            ..._transactions.asMap().entries.map((e) {
                              final tx = e.value;
                              final isPositive = tx.amount > 0;
                              return _TxTile(tx: _Tx(
                                tx.description,
                                tx.type,
                                tx.amount,
                                _timeAgo(tx.date),
                                isPositive ? Icons.add_circle_outline : Icons.shopping_bag_outlined,
                                isPositive ? AppColors.success : AppColors.error,
                              )).animate(delay: (80 * e.key).ms).fadeIn().slideX(begin: 0.05, end: 0);
                            }),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showTopUp(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Top Up Wallet', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text('Funds will be added via EFT', style: AppTextStyles.bodySmall),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                decoration: InputDecoration(
                  prefixText: 'R ',
                  prefixStyle: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  hintText: '0.00',
                  hintStyle: AppTextStyles.h2.copyWith(color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['500', '1000', '2000', '5000'].map((amt) => GestureDetector(
                  onTap: () => controller.text = amt,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text('R$amt', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text) ?? 0;
                    if (amount <= 0) return;
                    Navigator.pop(ctx);
                    try {
                      final result = await WalletService.topUp(amount: amount);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Top-up of R${amount.toStringAsFixed(2)} initiated. Ref: ${result.payment['reference'] ?? ''}'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                        _loadData();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                      }
                    }
                  },
                  child: const Text('Proceed to EFT'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tx {
  final String title, subtitle, time;
  final double amount;
  final IconData icon;
  final Color color;
  const _Tx(this.title, this.subtitle, this.amount, this.time, this.icon, this.color);
}

class _TxTile extends StatelessWidget {
  final _Tx tx;
  const _TxTile({required this.tx});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: tx.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(tx.icon, color: tx.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                Text(tx.subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.amount > 0 ? '+' : ''}R${tx.amount.abs().toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: tx.color),
              ),
              Text(tx.time, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  const _StatCard(this.value, this.label, this.color, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.subtitle.copyWith(color: color)),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
