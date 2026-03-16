import 'package:flutter/material.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/core/widgets/product_card.dart';
import 'package:spazasure_app/services/mock_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context)),
            // Search bar
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            // Categories
            SliverToBoxAdapter(child: _buildCategories()),
            // Featured banner
            SliverToBoxAdapter(child: _buildPromoBanner()),
            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Popular Products', style: AppTextStyles.h3),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/marketplace'),
                      child: Text('See All', style: AppTextStyles.body.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),
            // Product grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = MockData.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.pushNamed(context, '/product', arguments: product),
                      onAddToCart: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            action: SnackBarAction(label: 'VIEW CART', textColor: Colors.white, onPressed: () => Navigator.pushNamed(context, '/cart')),
                          ),
                        );
                      },
                    );
                  },
                  childCount: MockData.products.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.store, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning 👋', style: AppTextStyles.bodySmall),
                Text('Thabo\'s Spaza Shop', style: AppTextStyles.subtitle),
              ],
            ),
          ),
          // Notification bell
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/marketplace'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textHint),
              const SizedBox(width: 12),
              Text('Search products, suppliers...', style: AppTextStyles.body.copyWith(color: AppColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: MockData.categories.length,
        itemBuilder: (context, index) {
          final cat = MockData.categories[index];
          final icons = {
            'shopping_basket': Icons.shopping_basket,
            'local_drink': Icons.local_drink,
            'cookie': Icons.cookie,
            'spa': Icons.spa,
            'home': Icons.home,
            'child_care': Icons.child_care,
            'ac_unit': Icons.ac_unit,
            'bakery_dining': Icons.bakery_dining,
          };
          final colors = [
            AppColors.primary, AppColors.secondary, AppColors.accent,
            AppColors.info, const Color(0xFF8E24AA), AppColors.error,
            const Color(0xFF00ACC1), const Color(0xFF6D4C41),
          ];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/marketplace', arguments: cat.id),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icons[cat.iconName] ?? Icons.category,
                      color: colors[index % colors.length],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(cat.name, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.local_offer, size: 140, color: Colors.white.withValues(alpha: 0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('BULK DEAL', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  Text('Save up to 15%', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                  Text('on group bulk orders', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

