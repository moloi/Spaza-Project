import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/core/widgets/custom_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // ignore: unused_field
  String _otp = '';
  bool _isLoading = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  @override
  Widget build(BuildContext context) {
    final phone = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify Phone', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to +27 $phone',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              // OTP Fields
              PinCodeTextField(
                appContext: context,
                length: 6,
                onChanged: (value) => _otp = value,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.background,
                  selectedFillColor: AppColors.surface,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.divider,
                  selectedColor: AppColors.primary,
                ),
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
              ),
              const SizedBox(height: 16),
              // Resend
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Resend code in ${_resendTimer}s',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      )
                    : GestureDetector(
                        onTap: () {
                          setState(() => _resendTimer = 30);
                          _startTimer();
                        },
                        child: Text(
                          'Resend Code',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Verify',
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await Future.delayed(const Duration(seconds: 1));
                  if (!mounted) return;
                  setState(() => _isLoading = false);
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

