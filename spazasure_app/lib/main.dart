import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/main_shell.dart';
import 'features/marketplace/screens/marketplace_screen.dart';
import 'features/marketplace/screens/product_detail_screen.dart';
import 'features/cart/screens/cart_screen.dart';
import 'features/orders/screens/order_detail_screen.dart';
import 'features/delivery/screens/delivery_tracking_screen.dart';
import 'features/compliance/screens/compliance_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const SpazaSureApp());
}

class SpazaSureApp extends StatelessWidget {
  const SpazaSureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpazaSure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/otp': (_) => const OtpScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainShell(),
        '/marketplace': (_) => const MarketplaceScreen(),
        '/product': (_) => const ProductDetailScreen(),
        '/cart': (_) => const CartScreen(),
        '/order-detail': (_) => const OrderDetailScreen(),
        '/delivery-tracking': (_) => const DeliveryTrackingScreen(),
        '/compliance': (_) => const ComplianceScreen(),
        '/notifications': (_) => const NotificationsScreen(),
      },
    );
  }
}

