import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rachita/features/prescription/presentation/providers/drug_interaction_provider.dart';
import 'package:rachita/features/prescription/domain/services/drug_interaction_service.dart';
import 'package:rachita/shared/theme/app_colors.dart';

/// 🏥 لوحة التفاعلات الدوائية الحية — تظهر داخل شاشة الروشتة
/// تستخدم DrugInteractionService المتقدمة بالكامل
class LiveInteractionPanel extends ConsumerWidget {
  const LiveInteractionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(liveInteractionCheckProvider);
    final riskAssessment = ref.watch(liveRiskAssessmentProvider);

    return reportAsync.when(
      data: (report) {
        if (!report.hasAnyIssue && (riskAssessment == null || riskAssessment.riskScore < 20)) {
          return _buildSafeState();
        }

        return Column(
          children: [
            // لوحة مخاطر المريض
            if (riskAssessment != null && riskAssessment.riskScore >= 20)
              _buildRiskAssessmentCard(riskAssessment),
            // لوحة التفاعلات الدوائية
            if (report.hasAnyIssue)
              _buildInteractionPanel(report),
          ],
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('جاري فحص التعارضات الدوائية من قاعدة البيانات...', style: TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
      ),
      error: (e, st) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Text('خطأ في فحص التفاعلات: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
      ),
    );
  }

  Widget _buildSafeState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Color(0xFF4CAF50), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوصفة آمنة سريرياً ✓',
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text('لا تفاعلات دوائية ولا مخاطر مرتفعة مكتشفة',
                    style: TextStyle(color: Color(0xFF388E3C), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentCard(riskAssessment) {
    final score = riskAssessment.riskScore as int;
    final isHighRisk = score >= 60;
    final color = score >= 80
        ? const Color(0xFFD32F2F)
        : score >= 60
            ? const Color(0xFFF57C00)
            : const Color(0xFFF9A825);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHighRisk ? Icons.warning_rounded : Icons.info_outline_rounded,
                color: color, size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تقييم المخاطر: ${riskAssessment.riskLevel} ($score/100)',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riskAssessment.estimatedReviewFrequency,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if ((riskAssessment.riskFactors as List).isNotEmpty) ...[
            const SizedBox(height: 10),
            ...(riskAssessment.riskFactors as List<String>).take(3).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right_rounded, color: color, size: 16),
                      Expanded(
                          child: Text(f,
                              style: TextStyle(
                                  color: color.withOpacity(0.85),
                                  fontSize: 11))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionPanel(LiveInteractionReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: report.hasCritical
            ? const Color(0xFFB71C1C).withOpacity(0.06)
            : const Color(0xFFE65100).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: report.hasCritical
              ? const Color(0xFFD32F2F).withOpacity(0.35)
              : const Color(0xFFF57C00).withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: report.hasCritical
                  ? const Color(0xFFD32F2F).withOpacity(0.1)
                  : const Color(0xFFF57C00).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(
                  report.hasCritical
                      ? Icons.dangerous_rounded
                      : Icons.swap_horiz_rounded,
                  color: report.hasCritical
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFFF57C00),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.hasCritical
                        ? '🚨 تفاعلات دوائية حرجة مكتشفة!'
                        : '⚠️ تفاعلات دوائية تستحق المراجعة',
                    style: TextStyle(
                      color: report.hasCritical
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFFF57C00),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                _buildCountBadge(report),
              ],
            ),
          ),
          // قائمة التفاعلات
          ...report.allInteractions.take(4).map((interaction) =>
              _buildInteractionTile(interaction)),
          if (report.allInteractions.length > 4)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '+ ${report.allInteractions.length - 4} تفاعلات أخرى...',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(LiveInteractionReport report) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (report.criticalCount > 0)
          _badge('${report.criticalCount}', const Color(0xFFD32F2F)),
        if (report.highCount > 0) ...[
          const SizedBox(width: 4),
          _badge('${report.highCount}', const Color(0xFFF57C00)),
        ],
        if (report.moderateCount > 0) ...[
          const SizedBox(width: 4),
          _badge('${report.moderateCount}', const Color(0xFFF9A825)),
        ],
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInteractionTile(DrugInteractionResult interaction) {
    final color = interaction.isCritical
        ? const Color(0xFFD32F2F)
        : interaction.isHigh
            ? const Color(0xFFF57C00)
            : const Color(0xFFF9A825);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${interaction.drug1} ↔ ${interaction.drug2}',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (interaction.description != null)
            Text(
              interaction.description!,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
            ),
          if (interaction.recommendation != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      interaction.recommendation!,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 16, thickness: 0.5),
        ],
      ),
    );
  }
}
