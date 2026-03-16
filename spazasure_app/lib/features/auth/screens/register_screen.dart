import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentStep = 0;
  late AnimationController _bgController;

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(duration: 500.ms, curve: Curves.easeOutCubic);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: 500.ms, curve: Curves.easeOutCubic);
    }
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

          // Decorative elements
          Positioned(top: -60, left: -60, child: _GlowCircle(size: 180, color: const Color(0xFF4CAF50).withValues(alpha: 0.12))),
          Positioned(bottom: -80, right: -80, child: _GlowCircle(size: 220, color: const Color(0xFF81C784).withValues(alpha: 0.08))),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _currentStep > 0 ? _prevStep() : Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const Spacer(),
                      Text('Register', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: _AnimatedProgressBar(currentStep: _currentStep),
                ),

                // Form pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildOwnerDetails(),
                      _buildShopDetails(),
                      _buildDocumentUpload(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Owner Information', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Tell us about yourself', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _GlassTextField(controller: _nameController, label: 'Full Name', hint: 'Enter your full name', icon: Icons.person_outline_rounded),
                const SizedBox(height: 18),
                _GlassTextField(controller: _idController, label: 'ID Number', hint: 'Enter your SA ID number', icon: Icons.badge_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 18),
                _GlassTextField(controller: _phoneController, label: 'Phone Number', hint: '81 234 5678', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, prefix: '🇿🇦 +27'),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          _PremiumButton(text: 'Continue', icon: Icons.arrow_forward_rounded, onPressed: _nextStep),
        ],
      ),
    );
  }

  Widget _buildShopDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.store_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shop Details', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Tell us about your shop', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _GlassTextField(controller: _shopNameController, label: 'Shop Name', hint: 'Enter your shop name', icon: Icons.store_outlined),
                const SizedBox(height: 18),
                _GlassTextField(controller: _addressController, label: 'Physical Address', hint: 'Enter shop address', icon: Icons.location_on_outlined),
                const SizedBox(height: 18),
                _LocationCapture(),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          _PremiumButton(text: 'Continue', icon: Icons.arrow_forward_rounded, onPressed: _nextStep),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload() {
    final docs = [
      {'title': 'Business Permit', 'icon': Icons.description_outlined, 'required': true, 'color': const Color(0xFF4CAF50)},
      {'title': 'Health Certificate', 'icon': Icons.health_and_safety_outlined, 'required': true, 'color': const Color(0xFF2196F3)},
      {'title': 'Lease Agreement', 'icon': Icons.home_work_outlined, 'required': false, 'color': const Color(0xFFFF9800)},
      {'title': 'ID Document', 'icon': Icons.badge_outlined, 'required': true, 'color': const Color(0xFF9C27B0)},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.folder_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Upload Documents', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('For verification', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...docs.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _DocumentUploadTile(
                        title: e.value['title'] as String,
                        icon: e.value['icon'] as IconData,
                        required: e.value['required'] as bool,
                        color: e.value['color'] as Color,
                      ).animate(delay: (100 * e.key).ms).fadeIn().slideX(begin: 0.1, end: 0),
                    )),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          _PremiumButton(
            text: 'Submit Registration',
            icon: Icons.check_circle_rounded,
            onPressed: () => _showSuccessDialog(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 50),
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text('Registration Submitted! 🎉', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Your documents are under review.\nWe\'ll notify you once verified.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _PremiumButton(
                text: 'Continue to Login',
                icon: Icons.login_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.easeOut).fadeIn(),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _AnimatedProgressBar extends StatelessWidget {
  final int currentStep;
  const _AnimatedProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Owner', 'Shop', 'Documents']; // ignore: unused_local_variable
    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= currentStep;
        final isCompleted = i < currentStep;
        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: 400.ms,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF4CAF50) : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: 400.ms,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isActive ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]) : null,
                  color: isActive ? null : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? Colors.transparent : Colors.white.withValues(alpha: 0.2), width: 2),
                  boxShadow: isActive ? [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 12)] : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : Text('${i + 1}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
              if (i < 2)
                Expanded(
                  child: AnimatedContainer(
                    duration: 400.ms,
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < currentStep ? const Color(0xFF4CAF50) : Colors.white.withValues(alpha: 0.15),
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
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? prefix;

  const _GlassTextField({required this.controller, required this.label, required this.hint, required this.icon, this.keyboardType, this.prefix});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.35)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: prefix != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(prefix!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2)),
                        ],
                      ),
                    )
                  : Padding(padding: const EdgeInsets.only(left: 14), child: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 22)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationCapture extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF4CAF50).withValues(alpha: 0.15), const Color(0xFF2E7D32).withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GPS Location', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                Text('Tap to capture location', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

class _DocumentUploadTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool required;
  final Color color;

  const _DocumentUploadTile({required this.title, required this.icon, required this.required, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    if (required) Text(' *', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFFF5252))),
                  ],
                ),
                Text('Tap to upload', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.cloud_upload_outlined, color: color, size: 20),
          ),
        ],
      ),
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  const _PremiumButton({required this.text, required this.icon, required this.onPressed});

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: 150.ms,
        width: double.infinity,
        height: 56,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: _isPressed ? 0.2 : 0.4), blurRadius: _isPressed ? 10 : 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Icon(widget.icon, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
