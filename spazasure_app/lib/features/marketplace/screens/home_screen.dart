import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/core/widgets/product_card.dart';
import 'package:spazasure_app/providers/auth_provider.dart';
import 'package:spazasure_app/providers/cart_provider.dart';
import 'package:spazasure_app/services/product_service.dart';
import 'package:spazasure_app/services/mock_data.dart';
import 'package:spazasure_app/models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _walletVisible = false;
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingProducts = true);
    try {
      final results = await Future.wait([
        ProductService.getProducts(pageSize: 10),
        ProductService.getCategories(),
      ]);
      var products = results[0] as List<Product>;
      var categories = results[1] as List<Category>;

      // Use mock data if API returns empty (no products added by suppliers yet)
      if (products.isEmpty) products = MockData.products;
      if (categories.isEmpty) categories = MockData.categories;

      setState(() {
        _products = products;
        _categories = categories;
      });
    } catch (e) {
      // If API fails, use mock data so the app is usable
      setState(() {
        _products = MockData.products;
        _categories = MockData.categories;
      });
    } finally {
      setState(() => _loadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildWalletCard()),
            SliverToBoxAdapter(child: _buildKpiRow()),
            SliverToBoxAdapter(child: _buildActiveOrder()),
            SliverToBoxAdapter(child: _buildQuickActions()),
            SliverToBoxAdapter(child: _buildSectionTitle('Shop by Category', onTap: () => Navigator.pushNamed(context, '/marketplace'))),
            SliverToBoxAdapter(child: _buildCategories()),
            SliverToBoxAdapter(child: _buildPromoBanner()),
            SliverToBoxAdapter(child: _buildSectionTitle('Popular Products', onTap: () => Navigator.pushNamed(context, '/marketplace'))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: _loadingProducts
                  ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())))
                  : SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.pushNamed(context, '/product', arguments: product),
                      onAddToCart: () {
                        context.read<CartProvider>().add(product, product.minOrderQty);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${product.name} added to cart'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          action: SnackBarAction(label: 'VIEW CART', textColor: Colors.white, onPressed: () => Navigator.pushNamed(context, '/cart')),
                        ));
                      },
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PIECE 1: HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final auth = context.watch<AuthProvider>();
    final shopName = auth.session?.shopName ?? 'My Spaza Shop';
    final initials = shopName.isNotEmpty
        ? shopName.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : 'SP';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3B0F), Color(0xFF1B5E20)],
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getGreeting(), style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w400)),
                Text(shopName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Active', style: TextStyle(color: Color(0xFF69F0AE), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          // Search button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/marketplace'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Notifications
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Stack(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                ),
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1B5E20), width: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─── PIECE 2: PREMIUM WALLET CARD ───────────────────────────────────────────
  Widget _buildWalletCard() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/wallet'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D3B0F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1B5E20).withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(right: -30, top: -30, child: _decorCircle(120, 0.06)),
            Positioned(right: 40, bottom: -40, child: _decorCircle(100, 0.05)),
            Positioned(left: -20, bottom: -20, child: _decorCircle(80, 0.04)),
            // Card content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text('SpazaSure Wallet', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _walletVisible = !_walletVisible),
                        child: Icon(_walletVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white60, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _walletVisible ? 'R 4,097.10' : 'R ••••••',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text('Available Balance', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _walletAction(Icons.add_rounded, 'Top Up'),
                      const SizedBox(width: 10),
                      _walletAction(Icons.send_rounded, 'Transfer'),
                      const SizedBox(width: 10),
                      _walletAction(Icons.history_rounded, 'History'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Text('Manage', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0, delay: 100.ms, duration: 400.ms);
  }

  Widget _decorCircle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: opacity), shape: BoxShape.circle),
  );

  Widget _walletAction(IconData icon, String label) => Column(
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ],
  );

  // ─── PIECE 3: KPI STATS ROW ──────────────────────────────────────────────────
  Widget _buildKpiRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(child: _KpiCard(value: '3', label: 'Active Orders', color: AppColors.info, icon: Icons.receipt_long_rounded, trend: '+1 today')),
          const SizedBox(width: 10),
          Expanded(child: _KpiCard(value: '75%', label: 'Compliance', color: AppColors.warning, icon: Icons.verified_user_rounded, trend: '1 pending')),
          const SizedBox(width: 10),
          Expanded(child: _KpiCard(value: '4.8★', label: 'Rating', color: AppColors.success, icon: Icons.star_rounded, trend: 'Excellent')),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ─── PIECE 4: ACTIVE ORDER TRACKER ──────────────────────────────────────────
  Widget _buildActiveOrder() {
    final order = MockData.orders.first;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/orders'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.local_shipping_rounded, color: AppColors.info, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active Order', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        Text(order.orderNumber, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.statusDispatched.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('On the Way', style: TextStyle(color: AppColors.statusDispatched, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress steps
            _buildOrderProgress(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.supplierName} • ${order.items.length} items', style: AppTextStyles.caption),
                Text('R ${order.total.toStringAsFixed(2)}', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05, end: 0, delay: 250.ms, duration: 350.ms);
  }

  Widget _buildOrderProgress() {
    final steps = ['Confirmed', 'Processing', 'Dispatched', 'Delivered'];
    const currentStep = 2; // dispatched
    return Row(
      children: List.generate(steps.length, (i) {
        final isDone = i <= currentStep;
        final isCurrent = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 28 : 22,
                    height: isCurrent ? 28 : 22,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.primary : AppColors.divider,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)] : [],
                    ),
                    child: Icon(isDone ? Icons.check_rounded : Icons.circle, color: Colors.white, size: isCurrent ? 14 : 10),
                  ),
                  const SizedBox(height: 4),
                  Text(steps[i], style: TextStyle(fontSize: 9, color: isDone ? AppColors.primary : AppColors.textHint, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: i < currentStep ? [AppColors.primary, AppColors.primary] : [AppColors.primary, AppColors.divider],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ─── PIECE 5: QUICK ACTIONS ──────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.groups_rounded, 'label': 'Group Buy', 'color': AppColors.accent, 'route': '/group-buy', 'badge': null},
      {'icon': Icons.qr_code_scanner_rounded, 'label': 'Scan QR', 'color': AppColors.info, 'route': '/qr-scanner', 'badge': null},
      {'icon': Icons.description_outlined, 'label': 'Compliance', 'color': AppColors.warning, 'route': '/compliance', 'badge': '1'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Track Order', 'color': AppColors.secondary, 'route': '/home', 'badge': null},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: actions.map((a) => Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, a['route'] as String),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: (a['color'] as Color).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
                      ),
                      if (a['badge'] != null)
                        Positioned(
                          right: -4, top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                            child: Text(a['badge'] as String, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(a['label'] as String, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        )).toList(),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ─── PIECE 6: CATEGORIES ─────────────────────────────────────────────────────
  Widget _buildCategories() {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.info, const Color(0xFF8E24AA), AppColors.error, const Color(0xFF00ACC1), const Color(0xFF6D4C41)];
    final icons = {
      'shopping_basket': Icons.shopping_basket, 'local_drink': Icons.local_drink,
      'cookie': Icons.cookie, 'spa': Icons.spa, 'home': Icons.home,
      'child_care': Icons.child_care, 'ac_unit': Icons.ac_unit, 'bakery_dining': Icons.bakery_dining,
    };
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final color = colors[index % colors.length];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/marketplace', arguments: cat.id),
              child: Column(
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Icon(icons[cat.iconName] ?? Icons.category, color: color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(cat.name, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── PIECE 7: PROMO BANNER ───────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/group-buy'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        height: 130,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF57C00), Color(0xFFFF8F00), Color(0xFFFFB300)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned(right: -20, top: -20, child: _decorCircle(110, 0.12)),
            Positioned(right: 30, bottom: -30, child: _decorCircle(80, 0.1)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)),
                          child: const Text('🔥 LIMITED TIME', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        const Text('Save up to 20%', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        const Text('Join a group order now', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Text('Join Now', style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h3),
          GestureDetector(
            onTap: onTap,
            child: Text('See All', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}

// ─── KPI CARD WIDGET ──────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String value, label, trend;
  final Color color;
  final IconData icon;

  const _KpiCard({required this.value, required this.label, required this.color, required this.icon, required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(trend, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
