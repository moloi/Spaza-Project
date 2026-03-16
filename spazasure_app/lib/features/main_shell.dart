import 'package:flutter/material.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/features/marketplace/screens/home_screen.dart';
import 'package:spazasure_app/features/orders/screens/orders_screen.dart';
import 'package:spazasure_app/features/cart/screens/cart_screen.dart';
import 'package:spazasure_app/features/profile/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    OrdersScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _navItem(1, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
                _navItem(2, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart', badge: 3),
                _navItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, {int? badge}) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : AppColors.textHint,
                  size: 24,
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

