import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/core/widgets/status_badge.dart';
import 'package:spazasure_app/services/mock_data.dart';

class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

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
          children: [
            // Progress card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 45,
                    lineWidth: 8,
                    percent: progress,
                    center: Text('${(progress * 100).round()}%', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                    progressColor: Colors.white,
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
                        Text('$approvedCount of ${docs.length} documents verified', style: AppTextStyles.subtitle.copyWith(color: Colors.white)),
                        const SizedBox(height: 8),
                        if (progress < 1)
                          Text('Complete all documents to get verified badge', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Alert for expiring docs
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
                          Text('Your business permit expires in 14 days', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Documents list
            ...docs.map((doc) => _buildDocCard(context, doc)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, doc) {
    final icons = {
      'business_permit': Icons.description_outlined,
      'health_cert': Icons.health_and_safety_outlined,
      'lease': Icons.home_work_outlined,
      'id_document': Icons.badge_outlined,
    };
    final titles = {
      'business_permit': 'Business Permit',
      'health_cert': 'Health Certificate',
      'lease': 'Lease Agreement',
      'id_document': 'ID Document',
    };

    final isExpiringSoon = doc.expiryDate != null && doc.expiryDate!.difference(DateTime.now()).inDays < 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isExpiringSoon ? Border.all(color: AppColors.warning.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: doc.status == 'approved'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : doc.status == 'rejected'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icons[doc.docType] ?? Icons.description,
              color: doc.status == 'approved'
                  ? AppColors.success
                  : doc.status == 'rejected'
                      ? AppColors.error
                      : AppColors.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titles[doc.docType] ?? doc.docType, style: AppTextStyles.subtitle),
                const SizedBox(height: 2),
                if (doc.expiryDate != null)
                  Text(
                    isExpiringSoon
                        ? 'Expires in ${doc.expiryDate!.difference(DateTime.now()).inDays} days'
                        : 'Expires: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                    style: AppTextStyles.caption.copyWith(color: isExpiringSoon ? AppColors.warning : AppColors.textHint),
                  )
                else if (doc.status == 'pending')
                  Text('Under review', style: AppTextStyles.caption)
                else if (doc.status == 'rejected')
                  Text(doc.rejectionReason ?? 'Document rejected', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ],
            ),
          ),
          StatusBadge(status: doc.status),
        ],
      ),
    );
  }
}

