import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';

enum _ScanResult { authentic, warning, fake }

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  void _simulateScan() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isScanning = false);

    final result = _ScanResult.values[Random().nextInt(3)];
    _showResult(result);
  }

  void _showResult(_ScanResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScanResultSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('QR Product Scanner',
            style: AppTextStyles.subtitle.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera viewfinder background
          Container(
            color: const Color(0xFF0A0A0A),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Viewfinder frame
                  _buildViewfinder(),
                  const SizedBox(height: 32),
                  Text(
                    _isScanning ? 'Scanning...' : 'Point camera at product QR code',
                    style: AppTextStyles.body.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verify product authenticity instantly',
                    style: AppTextStyles.caption.copyWith(color: Colors.white38),
                  ),
                  const SizedBox(height: 48),
                  // Simulate scan button
                  _isScanning
                      ? const CircularProgressIndicator(
                          color: AppColors.primaryLight,
                          strokeWidth: 2,
                        )
                      : GestureDetector(
                          onTap: _simulateScan,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryLight,
                                  AppColors.primary
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_scanner_rounded,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 10),
                                Text('Simulate Scan',
                                    style: AppTextStyles.button),
                              ],
                            ),
                          ),
                        ).animate().fadeIn().scale(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        children: [
          // Dark overlay with cutout effect
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Corner brackets
          ..._buildCorners(),
          // Animated scan line
          AnimatedBuilder(
            animation: _scanLineController,
            builder: (_, __) => Positioned(
              top: 20 + (_scanLineController.value * 200),
              left: 16,
              right: 16,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primaryLight.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          // Center QR icon
          Center(
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 3.0;
    final color = AppColors.primaryLight;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(size: size, thickness: thickness, color: color,
            top: true, left: true),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(size: size, thickness: thickness, color: color,
            top: true, left: false),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(size: size, thickness: thickness, color: color,
            top: false, left: true),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(size: size, thickness: thickness, color: color,
            top: false, left: false),
      ),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double size;
  final double thickness;
  final Color color;
  final bool top;
  final bool left;

  const _Corner({
    required this.size,
    required this.thickness,
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
            color: color, thickness: thickness, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter(
      {required this.color,
      required this.thickness,
      required this.top,
      required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Result Bottom Sheet ──────────────────────────────────────────────────────

class _ScanResultSheet extends StatelessWidget {
  final _ScanResult result;
  const _ScanResultSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final config = _resultConfig(result);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Result icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 40),
          ).animate().scale(
              begin: const Offset(0.5, 0.5),
              duration: 500.ms,
              curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(config.title,
              style: AppTextStyles.h3.copyWith(color: config.color)),
          const SizedBox(height: 8),
          Text(config.subtitle,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Product info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: config.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: config.details
                  .map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(d.icon, size: 16, color: config.color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(d.label,
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary)),
                            ),
                            Text(d.value,
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons
          if (result == _ScanResult.fake) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/report');
                },
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Report This Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: config.color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Scan Another',
                  style: AppTextStyles.button.copyWith(color: config.color)),
            ),
          ),
        ],
      ),
    );
  }

  _ResultConfig _resultConfig(_ScanResult r) {
    switch (r) {
      case _ScanResult.authentic:
        return _ResultConfig(
          color: AppColors.success,
          icon: Icons.verified_rounded,
          title: '✅ Authentic Product',
          subtitle: 'This product has been verified and is safe to sell.',
          details: [
            _Detail(Icons.inventory_2_outlined, 'Product', 'Sunlight Dishwash 750ml'),
            _Detail(Icons.business_outlined, 'Brand', 'Unilever SA'),
            _Detail(Icons.workspace_premium_outlined, 'Certification', 'SABS Certified'),
            _Detail(Icons.calendar_today_outlined, 'Expiry', 'Dec 2026'),
            _Detail(Icons.qr_code_outlined, 'Batch', 'UL-2025-0042'),
          ],
        );
      case _ScanResult.warning:
        return _ResultConfig(
          color: AppColors.warning,
          icon: Icons.warning_amber_rounded,
          title: '⚠️ Incomplete Info',
          subtitle:
              'Some product details are missing. Verify with your supplier before selling.',
          details: [
            _Detail(Icons.inventory_2_outlined, 'Product', 'Generic Cooking Oil 2L'),
            _Detail(Icons.business_outlined, 'Brand', 'Unknown Supplier'),
            _Detail(Icons.workspace_premium_outlined, 'Certification', 'Not registered'),
            _Detail(Icons.calendar_today_outlined, 'Expiry', 'Not specified'),
            _Detail(Icons.info_outline, 'Safety Tip', 'Request invoice from supplier'),
          ],
        );
      case _ScanResult.fake:
        return _ResultConfig(
          color: AppColors.error,
          icon: Icons.dangerous_rounded,
          title: '❌ Counterfeit Detected',
          subtitle:
              'This product has been flagged as counterfeit. Do not sell. Report immediately.',
          details: [
            _Detail(Icons.inventory_2_outlined, 'Product', 'Fake Branded Juice 1L'),
            _Detail(Icons.business_outlined, 'Brand', 'Impersonating Clover SA'),
            _Detail(Icons.workspace_premium_outlined, 'Status', 'BLACKLISTED'),
            _Detail(Icons.report_outlined, 'Reports', '14 reports filed'),
            _Detail(Icons.gavel_outlined, 'Action', 'Report to authorities'),
          ],
        );
    }
  }
}

class _ResultConfig {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_Detail> details;

  _ResultConfig({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.details,
  });
}

class _Detail {
  final IconData icon;
  final String label;
  final String value;
  _Detail(this.icon, this.label, this.value);
}
