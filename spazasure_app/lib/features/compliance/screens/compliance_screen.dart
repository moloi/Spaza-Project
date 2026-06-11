import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spazasure_app/core/constants/app_colors.dart';
import 'package:spazasure_app/core/constants/app_text_styles.dart';
import 'package:spazasure_app/providers/compliance_provider.dart';
import 'package:spazasure_app/services/compliance_service.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  static const _requiredDocs = [
    _DocMeta('business_license', 'Business License', Icons.storefront_rounded, 'Local Municipality', 'https://www.cogta.gov.za', true),
    _DocMeta('health_permit', 'Health Permit', Icons.health_and_safety_rounded, 'Dept. of Health', 'https://www.health.gov.za', true),
    _DocMeta('food_handler', 'Food Handler Certificate', Icons.restaurant_rounded, 'Dept. of Health', 'https://www.health.gov.za', true),
    _DocMeta('id_copy', 'ID Document (Copy)', Icons.badge_rounded, 'Home Affairs', 'https://www.dha.gov.za', true),
    _DocMeta('proof_of_address', 'Proof of Address', Icons.location_on_rounded, 'Utility / Bank', 'https://www.gov.za', true),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplianceProvider>().loadStatus();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Consumer<ComplianceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.documents.isEmpty) {
            return _buildLoadingState();
          }

          if (provider.error != null && provider.documents.isEmpty) {
            return _buildErrorState(provider);
          }

          return _buildContent(provider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(null),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildShimmerCard(height: 160),
              const SizedBox(height: 16),
              _buildShimmerCard(height: 80),
              const SizedBox(height: 12),
              _buildShimmerCard(height: 80),
              const SizedBox(height: 12),
              _buildShimmerCard(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) => Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _shimmerController.value, 0),
            end: Alignment(1 + 2 * _shimmerController.value, 0),
            colors: const [Color(0xFFEEEEEE), Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ComplianceProvider provider) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(null),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.error),
                  ),
                  const SizedBox(height: 20),
                  Text('Connection Error', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load your compliance data.\nPlease check your internet connection.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => provider.loadStatus(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(ComplianceStatus? status) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Compliance', style: AppTextStyles.h3),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          onPressed: () => context.read<ComplianceProvider>().loadStatus(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildContent(ComplianceProvider provider) {
    final status = provider.status;
    final docs = provider.documents;
    final totalRequired = status?.totalRequired ?? _requiredDocs.length;
    final approvedCount = status?.approved ?? 0;
    final pendingCount = status?.pending ?? 0;
    final progress = totalRequired > 0 ? approvedCount / totalRequired : 0.0;

    return RefreshIndicator(
      onRefresh: () => provider.loadStatus(),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(status),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero progress card
                _buildHeroCard(progress, approvedCount, pendingCount, totalRequired, status?.overallStatus ?? 'red')
                    .animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 20),

                // Stats row
                _buildStatsRow(approvedCount, pendingCount, totalRequired - approvedCount - pendingCount)
                    .animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 24),

                // Section header
                Row(
                  children: [
                    Container(
                      width: 4, height: 20,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 10),
                    Text('Required Documents', style: AppTextStyles.h3),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 6),
                Text('Upload all documents to get your verified badge', style: AppTextStyles.bodySmall),
                const SizedBox(height: 16),

                // Document cards — one per required doc type
                ..._buildDocumentCards(docs, provider),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(double progress, int approved, int pending, int total, String overallStatus) {
    final isComplete = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isComplete
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF0D3B0F), const Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircularPercentIndicator(
                radius: 52,
                lineWidth: 10,
                percent: progress.clamp(0.0, 1.0),
                animation: true,
                animationDuration: 1200,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(progress * 100).round()}%',
                      style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20)),
                  ],
                ),
                progressColor: isComplete ? const Color(0xFF81C784) : const Color(0xFF66BB6A),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COMPLIANCE STATUS',
                      style: AppTextStyles.caption.copyWith(color: Colors.white60, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(isComplete ? 'Fully Verified ✓' : '$approved of $total approved',
                      style: AppTextStyles.h3.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    if (!isComplete && pending > 0)
                      Text('$pending pending review',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                    if (isComplete)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF81C784)),
                            const SizedBox(width: 6),
                            Text('Verified Shop', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(int approved, int pending, int missing) {
    return Row(
      children: [
        Expanded(child: _buildStatChip(Icons.check_circle_rounded, '$approved', 'Approved', const Color(0xFF2E7D32))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatChip(Icons.hourglass_top_rounded, '$pending', 'Pending', AppColors.warning)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatChip(Icons.upload_file_rounded, '${missing < 0 ? 0 : missing}', 'Missing', AppColors.error)),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.subtitle.copyWith(color: color, fontWeight: FontWeight.w700)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  List<Widget> _buildDocumentCards(List<ComplianceDocument> docs, ComplianceProvider provider) {
    final widgets = <Widget>[];
    final docsByType = {for (var d in docs) d.docType: d};

    for (var i = 0; i < _requiredDocs.length; i++) {
      final meta = _requiredDocs[i];
      final doc = docsByType[meta.type];
      widgets.add(
        _buildDocumentCard(meta, doc, provider)
            .animate(delay: (250 + (i * 80)).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.03, end: 0, duration: 400.ms),
      );
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  Widget _buildDocumentCard(_DocMeta meta, ComplianceDocument? doc, ComplianceProvider provider) {
    final status = doc?.status ?? 'missing';
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';
    final isMissing = status == 'missing' || doc == null;
    final isUploading = provider.uploadingDocType == meta.type;

    final isExpiring = doc?.expiryDate != null && (() {
      final expiry = DateTime.tryParse(doc!.expiryDate!);
      return expiry != null && expiry.difference(DateTime.now()).inDays < 30;
    })();

    // Determine status color
    final Color statusColor;
    final String statusIcon;
    final String statusLabel;
    if (isApproved && !isExpiring) {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = '✓';
      statusLabel = 'Approved';
    } else if (isPending) {
      statusColor = AppColors.warning;
      statusIcon = '◎';
      statusLabel = 'Under Review';
    } else if (isRejected) {
      statusColor = AppColors.error;
      statusIcon = '✗';
      statusLabel = 'Rejected';
    } else if (isExpiring) {
      statusColor = AppColors.warning;
      statusIcon = '⚠';
      statusLabel = 'Expiring Soon';
    } else {
      statusColor = AppColors.textHint;
      statusIcon = '○';
      statusLabel = 'Not Uploaded';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isApproved ? statusColor.withValues(alpha: 0.25) : statusColor.withValues(alpha: 0.15),
          width: isApproved ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withValues(alpha: 0.12), statusColor.withValues(alpha: 0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(meta.icon, color: statusColor, size: 26),
                ),
                const SizedBox(width: 14),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.title, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                      const SizedBox(height: 3),
                      if (isRejected && doc?.rejectionNote != null)
                        Text('Reason: ${doc!.rejectionNote}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.error),
                          maxLines: 2, overflow: TextOverflow.ellipsis)
                      else if (isPending)
                        Text('Submitted • Awaiting admin review', style: AppTextStyles.caption.copyWith(color: AppColors.warning))
                      else if (isExpiring)
                        Builder(builder: (_) {
                          final expiry = DateTime.tryParse(doc!.expiryDate!);
                          final days = expiry?.difference(DateTime.now()).inDays ?? 0;
                          return Text('⚠ Expires in $days days — renew soon', style: AppTextStyles.caption.copyWith(color: AppColors.warning));
                        })
                      else if (isApproved)
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 13, color: statusColor),
                            const SizedBox(width: 4),
                            Text('Verified', style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                            if (doc?.expiryDate != null) ...[
                              Text(' • ', style: AppTextStyles.caption),
                              Builder(builder: (_) {
                                final expiry = DateTime.tryParse(doc!.expiryDate!);
                                if (expiry == null) return const SizedBox.shrink();
                                return Text('Exp. ${expiry.day}/${expiry.month}/${expiry.year}', style: AppTextStyles.caption);
                              }),
                            ],
                          ],
                        )
                      else
                        Text('Required • Not yet uploaded', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action bar (show for non-approved or expiring)
          if (!isApproved || isRejected || isExpiring)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // How to get
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showHowToSheet(meta),
                      icon: Icon(Icons.info_outline_rounded, size: 15, color: AppColors.info),
                      label: Text('How to get', style: AppTextStyles.caption.copyWith(color: AppColors.info, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                  Container(width: 1, height: 24, color: AppColors.divider),
                  // Upload button
                  Expanded(
                    child: isUploading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                            ),
                          )
                        : TextButton.icon(
                            onPressed: () => _showUploadSheet(meta.type, meta.title, provider),
                            icon: Icon(Icons.cloud_upload_rounded, size: 15, color: AppColors.primary),
                            label: Text(
                              isRejected ? 'Re-upload' : 'Upload',
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom Sheets ─────────────────────────────────────────────────────────

  void _showHowToSheet(_DocMeta meta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              // Header
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.info.withValues(alpha: 0.15), AppColors.info.withValues(alpha: 0.05)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(meta.icon, color: AppColors.info, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meta.title, style: AppTextStyles.h3.copyWith(fontSize: 17)),
                        Text('How to obtain this document', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Steps
              _buildStep(1, 'Visit your nearest ${meta.department} office', Icons.location_on_outlined),
              _buildStep(2, 'Bring your ID document and proof of address', Icons.badge_outlined),
              _buildStep(3, 'Complete the application form', Icons.edit_note_rounded),
              _buildStep(4, 'Pay the applicable fee (if any)', Icons.payment_rounded),
              _buildStep(5, 'Upload the issued document here', Icons.cloud_upload_rounded),
              const SizedBox(height: 20),
              // Link card
              if (meta.url.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.open_in_new_rounded, color: AppColors.info, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meta.department, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.info)),
                            Text(meta.url, style: AppTextStyles.caption.copyWith(color: AppColors.info)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int num, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('$num', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  void _showUploadSheet(String docType, String docTitle, ComplianceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              Text('Upload $docTitle', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text('Choose how you want to upload your document', style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),
              // Camera option
              _buildUploadOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take a Photo',
                subtitle: 'Use your camera to capture the document',
                color: AppColors.primary,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadImage(docType, provider);
                },
              ),
              const SizedBox(height: 12),
              // File picker option
              _buildUploadOption(
                icon: Icons.folder_open_rounded,
                title: 'Choose from Files',
                subtitle: 'Select a PDF, JPG, or PNG file',
                color: AppColors.info,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadFile(docType, provider);
                },
              ),
              const SizedBox(height: 20),
              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Max 5MB • Accepted: PDF, JPG, PNG\nDocument will be reviewed by admin within 24–48 hours',
                        style: AppTextStyles.caption.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textHint.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Upload Handlers ──────────────────────────────────────────────────────

  Future<void> _pickAndUploadImage(String docType, ComplianceProvider provider) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920, imageQuality: 85);
    if (image == null) return;

    final success = await provider.uploadDocument(docType: docType, filePath: image.path);
    _showUploadResult(success, provider.error);
  }

  Future<void> _pickAndUploadFile(String docType, ComplianceProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;

    final success = await provider.uploadDocument(docType: docType, filePath: result.files.single.path!);
    _showUploadResult(success, provider.error);
  }

  void _showUploadResult(bool success, String? error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              success
                  ? 'Document uploaded! Admin will review within 24–48hrs.'
                  : 'Upload failed: ${error ?? "Unknown error"}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: success ? 3 : 5),
    ));
  }
}

class _DocMeta {
  final String type, title, department, url;
  final IconData icon;
  final bool required;
  const _DocMeta(this.type, this.title, this.icon, this.department, this.url, this.required);
}
