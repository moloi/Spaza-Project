import 'package:flutter/material.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/core/widgets/product_card.dart';
import 'package:spazasure_app/services/mock_data.dart';
import 'package:spazasure_app/models/models.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _sortBy = 'popular';
  List<Product> _filteredProducts = MockData.products;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final catId = ModalRoute.of(context)?.settings.arguments as String?;
    if (catId != null && _selectedCategory == null) {
      _selectedCategory = catId;
      _filterProducts();
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = MockData.products.where((p) {
        final matchesSearch = _searchController.text.isEmpty ||
            p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            p.supplierName.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesCategory = _selectedCategory == null || p.categoryId == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();

      // Sort
      switch (_sortBy) {
        case 'price_low':
          _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_high':
          _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        default:
          _filteredProducts.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterProducts(),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Category chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: MockData.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        _selectedCategory = null;
                        _filterProducts();
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }
                final cat = MockData.categories[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(cat.name),
                    selected: _selectedCategory == cat.id,
                    onSelected: (_) {
                      _selectedCategory = _selectedCategory == cat.id ? null : cat.id;
                      _filterProducts();
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              },
            ),
          ),
          // Results count & sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_filteredProducts.length} products', style: AppTextStyles.bodySmall),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Row(
                    children: [
                      const Icon(Icons.sort, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Sort', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Products grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text('No products found', style: AppTextStyles.subtitle),
                        Text('Try adjusting your search or filters', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => Navigator.pushNamed(context, '/product', arguments: product),
                        onAddToCart: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            ...['popular', 'price_low', 'price_high', 'rating'].map((opt) {
              final labels = {'popular': 'Most Popular', 'price_low': 'Price: Low to High', 'price_high': 'Price: High to Low', 'rating': 'Highest Rated'};
              return ListTile(
                title: Text(labels[opt]!),
                trailing: _sortBy == opt ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  _sortBy = opt;
                  _filterProducts();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: AppTextStyles.h3),
                  TextButton(
                    onPressed: () {
                      _selectedCategory = null;
                      _filterProducts();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Categories', style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MockData.categories.map((cat) => FilterChip(
                      label: Text(cat.name),
                      selected: _selectedCategory == cat.id,
                      onSelected: (_) {
                        setState(() => _selectedCategory = _selectedCategory == cat.id ? null : cat.id);
                      },
                    )).toList(),
              ),
              const SizedBox(height: 24),
              Text('Suppliers', style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MockData.suppliers.map((s) => FilterChip(
                      label: Text(s.companyName),
                      selected: false,
                      onSelected: (_) {},
                    )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

