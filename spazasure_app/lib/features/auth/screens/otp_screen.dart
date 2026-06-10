import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:spazasure_app/providers/auth_provider.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  String _otp = '';
  bool _isLoading = false;
  int _resendTimer = 30;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _startTimer();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
        return true;
      }
      return false;
    });
  }

  Map<String, dynamic> _args(BuildContext context) =>
      (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};

  Future<void> _verify(BuildContext context) async {
    if (_otp.length != 6) return;
    final args = _args(context);
    final phone = args['phone'] as String? ?? '';
    final purpose = args['purpose'] as String? ?? 'login';

    setState(() => _isLoading = true);
    try {
      if (purpose == 'login') {
        await context.read<AuthProvider>().verifyLogin(phone, _otp);
      } else {
        await context.read<AuthProvider>().verifyRegister(
          phone: phone,
          otp: _otp,
          fullName: args['fullName'] as String? ?? '',
          shopName: args['shopName'] as String? ?? '',
          address: args['address'] as String? ?? '',
          idNumber: args['idNumber'] as String?,
        );
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend(BuildContext context) async {
    final args = _args(context);
    final phone = args['phone'] as String? ?? '';
    final purpose = args['purpose'] as String? ?? 'login';
    try {
      if (purpose == 'login') {
        await context.read<AuthProvider>().sendLoginOtp(phone);
      } else {
        await context.read<AuthProvider>().sendRegisterOtp(phone);
      }
      setState(() => _resendTimer = 30);
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args(context);
    final phone = args['phone'] as String? ?? '';

    return Scaffold(
      body: Stack(
        children: [
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
          Positioned(top: -80, right: -80, child: _GlowCircle(size: 200, color: const Color(0xFF4CAF50).withValues(alpha: 0.15))),
          Positioned(bottom: -100, left: -100, child: _GlowCircle(size: 250, color: const Color(0xFF81C784).withValues(alpha: 0.1))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: const Icon(Icons.sms_rounded, color: Colors.white, size: 44),
                  ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut).fadeIn(),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        Text('Verify Your Number',
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(
                          phone.isNotEmpty
                              ? 'We sent a 6-digit code to\n$phone'
                              : 'Enter the 6-digit code we sent you',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          onChanged: (v) => _otp = v,
                          onCompleted: (_) => _verify(context),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(14),
                            fieldHeight: 56,
                            fieldWidth: 46,
                            activeFillColor: Colors.white.withValues(alpha: 0.15),
                            inactiveFillColor: Colors.white.withValues(alpha: 0.08),
                            selectedFillColor: Colors.white.withValues(alpha: 0.2),
                            activeColor: const Color(0xFF4CAF50),
                            inactiveColor: Colors.white.withValues(alpha: 0.2),
                            selectedColor: Colors.white,
                          ),
                          enableActiveFill: true,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.scale,
                          textStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                          cursorColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        _resendTimer > 0
                            ? Text(
                                'Resend code in ${_resendTimer}s',
                                style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                              )
                            : GestureDetector(
                                onTap: () => _resend(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Text('Resend Code',
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                ),
                              ),
                        const SizedBox(height: 28),
                        _VerifyButton(
                          isLoading: _isLoading,
                          onPressed: () => _verify(context),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0, delay: 300.ms),
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
  Widget build(BuildContext context) => Container(
      width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _VerifyButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _VerifyButton({required this.isLoading, required this.onPressed});
  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity, height: 56,
        transform: Matrix4.diagonal3Values(_pressed ? 0.97 : 1.0, _pressed ? 0.97 : 1.0, 1.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: _pressed ? 0.2 : 0.4),
              blurRadius: _pressed ? 10 : 20,
              offset: const Offset(0, 8))],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Verify & Continue',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
