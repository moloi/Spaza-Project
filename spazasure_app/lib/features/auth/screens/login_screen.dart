import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(sin(_bgController.value * 2 * pi), cos(_bgController.value * 2 * pi)),
                  end: Alignment(-sin(_bgController.value * 2 * pi), -cos(_bgController.value * 2 * pi)),
                  colors: const [Color(0xFF0D3B0F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
              ),
            ),
          ),

          // Decorative circles
          Positioned(top: -80, right: -80, child: _GlowCircle(size: 200, color: const Color(0xFF4CAF50).withValues(alpha: 0.15))),
          Positioned(bottom: -100, left: -100, child: _GlowCircle(size: 250, color: const Color(0xFF81C784).withValues(alpha: 0.1))),
          Positioned(top: 200, left: -50, child: _GlowCircle(size: 100, color: Colors.white.withValues(alpha: 0.05))),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  // Logo with glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        'https://scontent-jnb2-1.xx.fbcdn.net/v/t39.30808-1/653020711_1424406249698105_8820913488625060074_n.jpg?stp=dst-jpg_s200x200_tt6&_nc_cat=101&ccb=1-7&_nc_sid=2d3e12&_nc_ohc=YKNgAelbXu4Q7kNvwHbbECs&_nc_oc=Adk6YbLS033Z2M6WAWMa5goUkIclyNKBPWV59PEQvGMd6s7Zx5cvKZw2a8zvFWTYtMQ&_nc_zt=24&_nc_ht=scontent-jnb2-1.xx&_nc_gid=FVVhRzgT-n-01gLVxTgH-w&_nc_ss=8&oh=00_AfxuzTglv_sNi5mN3yzhdvl8b9oBGu2Svdh-10lsHQSjnw&oe=69BE0ACB',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.store_rounded, size: 50, color: AppColors.primary),
                      ),
                    ),
                  )
                      .animate()
                      .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  Text(
                    'SpazaSure',
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0, delay: 200.ms),

                  const SizedBox(height: 40),

                  // Glass card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back! 👋',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue to your shop',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 32),

                        // Phone input
                        Text('Phone Number', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: '81 234 5678',
                              hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.4)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Container(
                                padding: const EdgeInsets.only(left: 16, right: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🇿🇦', style: TextStyle(fontSize: 22)),
                                    const SizedBox(width: 8),
                                    Text('+27', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 10),
                                    Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Login button
                        _AnimatedButton(
                          text: 'Continue',
                          isLoading: _isLoading,
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            await Future.delayed(const Duration(seconds: 1));
                            if (!mounted) return;
                            setState(() => _isLoading = false);
                            Navigator.pushNamed(context, '/otp', arguments: _phoneController.text);
                          },
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('or', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                            ),
                            Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Social buttons
                        Row(
                          children: [
                            Expanded(child: _SocialButton(icon: Icons.g_mobiledata_rounded, label: 'Google')),
                            const SizedBox(width: 12),
                            Expanded(child: _SocialButton(icon: Icons.facebook_rounded, label: 'Facebook')),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.15, end: 0, delay: 400.ms, duration: 600.ms, curve: Curves.easeOut),

                  const SizedBox(height: 28),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Register', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  const _AnimatedButton({required this.text, required this.isLoading, required this.onPressed});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 56,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: _isPressed ? 0.2 : 0.4), blurRadius: _isPressed ? 10 : 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
