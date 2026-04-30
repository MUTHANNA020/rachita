import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/clinical_reasoning_engine.dart';
import '../../../patient/domain/entities/patient_entity.dart';
import '../providers/medical_intelligence_providers.dart';

/// 🩺 لوحة البصيرة السريرية - Clinical Insight Panel
/// 
/// تعرض استنتاجات النظام الذكي بشكل مرئي وتفاعلي، مما يظهر "الذكاء الحقيقي" خلف الكواليس.
class ClinicalInsightPanel extends ConsumerWidget {
  final PatientEntity patient;
  final String diagnosis;
  final List<String> medicines;
  final Map<String, double>? vitals;

  const ClinicalInsightPanel({
    super.key,
    required this.patient,
    required this.diagnosis,
    required this.medicines,
    this.vitals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(clinicalReasoningEngineProvider);

    return FutureBuilder<ClinicalInferenceResult>(
      future: engine.analyzeSituation(
        patient: patient,
        currentDiagnosis: diagnosis,
        prescribedMedicines: medicines,
        vitals: vitals,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.insights.isEmpty) {
          return const SizedBox.shrink();
        }

        final result = snapshot.data!;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تحليل الذكاء السريري',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'حالة التحليل: ${result.status}',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildConfidenceIndicator(result.confidenceScore),
                ],
              ),
              const SizedBox(height: 20),
              ...result.insights.map((insight) => _buildInsightTile(insight)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightTile(ClinicalInsight insight) {
    final iconColor = insight.severity == InsightSeverity.critical ? Colors.redAccent : Colors.orangeAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.explanation,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'توصية: ${insight.recommendation}',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(int score) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$score%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          const Text('دقة الاستنتاج', style: TextStyle(color: Colors.white70, fontSize: 8)),
        ],
      ),
    );
  }
}
