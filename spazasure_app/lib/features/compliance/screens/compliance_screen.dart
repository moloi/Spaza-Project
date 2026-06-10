import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/core/widgets/status_badge.dart';
import 'package:spazasure_app/services/mock_data.dart';

class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  static const _docMeta = {
    'business_permit': _DocMeta('Business Permit', Icons.description_outlined, 'Local Municipality', 'https://www.cogta.gov.za', true),
    'health_cert': _DocMeta('Health Certificate', Icons.health_and_safety_outlined, 'Dept. of Health', 'https://www.health.gov.za', true),
    'lease': _DocMeta('Lease Agreement', Icons.home_work_outlined, 'Download Template', 'https://www.justice.gov.za', false),
    'id_document': _DocMeta('ID Document', Icons.badge_outlined, 'Dept. of Home Affairs', 'https://www.dha.gov.za', true),
  };

  @override
  Widget build(BuildContext context) {
    final docs = MockData.complianceDocs;
    final approvedCount = docs.where((d) => d.status == 'approved').length;
    final progress = approvedCount / docs.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Compliance'), backgroundColor: AppColors.surface),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D3B0F), Color(0xFF1B5E20)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 48,
                    lineWidth: 8,
                    percent: progress,
                    center: Text('${(progress * 100).round()}%', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                    progressColor: const Color(0xFF4CAF50),
                    backgroundColor: Colors.white24,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Compliance Status', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text('$approvedCount of ${docs.length} verified', style: AppTextStyles.subtitle.copyWith(color: Colors.white)),
                        const SizedBox(height: 8),
                        if (progress < 1)
                          Text('Complete all docs to get your\n🟢 Verified Badge', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                        if (progress >= 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                            child: Text('✅ Fully Verified', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // Scan Product QR button
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Product QR',
                              style: AppTextStyles.subtitle
                                  .copyWith(color: Colors.white)),
                          Text('Verify product authenticity instantly',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Document Status Guide', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _legendDot(const Color(0xFF4CAF50)), const SizedBox(width: 6), Expanded(child: Text('Verified & complete', style: AppTextStyles.caption)),
                      _legendDot(AppColors.warning), const SizedBox(width: 6), Expanded(child: Text('Incomplete — guidance available', style: AppTextStyles.caption)),
                      _legendDot(AppColors.error), const SizedBox(width: 6), Expanded(child: Text('Not registered', style: AppTextStyles.caption)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // Expiry alert
            if (docs.any((d) => d.expiryDate != null && d.expiryDate!.difference(DateTime.now()).inDays < 30))
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Document Expiring Soon', style: AppTextStyles.subtitle.copyWith(color: AppColors.warning)),
                          Text('Your business permit expires in 14 days. Renew now.', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

            Text('Your Documents', style: AppTextStyles.h3),
            const SizedBox(height: 12),

            ...docs.asMap().entries.map((e) =>
              _buildDocCard(context, e.value).animate(delay: (80 * e.key).ms).fadeIn().slideX(begin: 0.05, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _buildDocCard(BuildContext context, dynamic doc) {
    final meta = _docMeta[doc.docType];
    if (meta == null) return const SizedBox.shrink();

    final isExpiringSoon = doc.expiryDate != null && doc.expiryDate!.difference(DateTime.now()).inDays < 30;
    final isApproved = doc.status == 'approved';
    final isPending = doc.status == 'pending';
    final isRejected = doc.status == 'rejected';

    // Traffic light color
    Color trafficColor;
    String trafficLabel;
    if (isApproved && !isExpiringSoon) {
      trafficColor = const Color(0xFF4CAF50);
      trafficLabel = '🟢';
    } else if (isPending || isExpiringSoon) {
      trafficColor = AppColors.warning;
      trafficLabel = '🟠';
    } else {
      trafficColor = AppColors.error;
      trafficLabel = '🔴';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trafficColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: trafficColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(meta.icon, color: trafficColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(trafficLabel, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(meta.title, style: AppTextStyles.subtitle)),
                          if (meta.required)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text('Required', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (doc.expiryDate != null)
                        Text(
                          isExpiringSoon
                              ? '⚠️ Expires in ${doc.expiryDate!.difference(DateTime.now()).inDays} days'
                              : 'Expires: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                          style: AppTextStyles.caption.copyWith(color: isExpiringSoon ? AppColors.warning : AppColors.textHint),
                        )
                      else if (isPending)
                        Text('Under review by admin', style: AppTextStyles.caption.copyWith(color: AppColors.warning))
                      else if (isRejected)
                        Text(doc.rejectionReason ?? 'Document rejected — please re-upload', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
                StatusBadge(status: doc.status),
              ],
            ),
          ),
          // How-to link for incomplete/pending docs
          if (!isApproved || isExpiringSoon)
            Container(
              decoration: BoxDecoration(
                color: trafficColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: trafficColor.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showHowTo(context, meta),
                      icon: Icon(Icons.help_outline_rounded, size: 16, color: trafficColor),
                      label: Text('How to get this document', style: AppTextStyles.caption.copyWith(color: trafficColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Container(width: 1, height: 32, color: trafficColor.withValues(alpha: 0.15)),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showUpload(context, meta.title),
                      icon: Icon(Icons.cloud_upload_outlined, size: 16, color: trafficColor),
                      label: Text('Upload Document', style: AppTextStyles.caption.copyWith(color: trafficColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showHowTo(BuildContext context, _DocMeta meta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(meta.icon, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('How to get: ${meta.title}', style: AppTextStyles.h3)),
              ],
            ),
            const SizedBox(height: 20),
            _howToStep('1', 'Visit your nearest ${meta.department} office'),
            _howToStep('2', 'Bring your ID document and proof of address'),
            _howToStep('3', 'Complete the application form'),
            _howToStep('4', 'Pay the applicable fee (if any)'),
            _howToStep('5', 'Upload the document here once received'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meta.department, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.info)),
                        Text(meta.url, style: AppTextStyles.caption.copyWith(color: AppColors.info)),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, color: AppColors.info, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _howToStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text(num, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  void _showUpload(BuildContext context, String docTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Upload $docTitle', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            _uploadOption(context, Icons.camera_alt_outlined, 'Take a Photo', 'Use your camera'),
            const SizedBox(height: 10),
            _uploadOption(context, Icons.folder_outlined, 'Choose from Files', 'PDF, JPG, PNG'),
            const SizedBox(height: 20),
            Text('Max file size: 5MB • Accepted: PDF, JPG, PNG', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _uploadOption(BuildContext context, IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Document uploaded for review'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subtitle),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _DocMeta {
  final String title, department, url;
  final IconData icon;
  final bool required;
  const _DocMeta(this.title, this.icon, this.department, this.url, this.required);
}
