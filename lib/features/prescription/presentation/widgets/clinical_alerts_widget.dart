import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medical_intelligence_providers.dart';
import '../../domain/services/risk_assessment_service.dart';
import '../../domain/hybrid_suggestion_engine.dart';
import '../../domain/medical_entity_resolver.dart';

/// 🏥 واجهة عرض التنبيهات السريرية الشاملة
class ClinicalAlertsWidget extends ConsumerWidget {
  final String patientId;
  final String prescriptionId;
  final HybridSuggestionParams suggestionParams;

  const ClinicalAlertsWidget({
    super.key,
    required this.patientId,
    required this.prescriptionId,
    required this.suggestionParams,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(hybridSuggestionsProvider(suggestionParams));
    final riskAsync = ref.watch(
      patientRiskAssessmentProvider(PatientRiskParams(
        age: suggestionParams.patientAge,
        ageCategory: suggestionParams.ageCategory,
        isPregnant: suggestionParams.isPregnant ?? false,
        chronicDiseases: suggestionParams.chronicDiseases,
        allergies: suggestionParams.allergies,
        systolic: suggestionParams.systolic,
        diastolic: suggestionParams.diastolic,
        bloodSugar: suggestionParams.sugar,
        currentMedicines: suggestionParams.currentMedicines,
      )),
    );

    return suggestionsAsync.when(
      data: (suggestions) => riskAsync.when(
        data: (risk) => _buildUI(context, ref, suggestions, risk),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ في تقييم المخاطر: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ في التوصيات: $e')),
    );
  }

  Widget _buildUI(BuildContext context, WidgetRef ref,
      HybridSuggestionResult s, PatientRiskAssessment risk) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _riskCard(risk),
          const SizedBox(height: 20),
          // 🚨 تفاعلات الأدوية — بطاقات غنية بالمعلومات
          if (s.drugInteractionAlerts.isNotEmpty) ...[
            _sectionHeader('تفاعلات الأدوية', Icons.dangerous_outlined,
                Colors.red, s.drugInteractionAlerts.length),
            const SizedBox(height: 8),
            for (final w in s.drugInteractionAlerts) _interactionCard(w),
            const SizedBox(height: 12),
          ],
          // ⚠️ الحساسية
          if (s.allergyAlerts.isNotEmpty) ...[
            _alertSection('تحذيرات الحساسية', s.allergyAlerts,
                Icons.warning_amber_rounded, Colors.red),
            const SizedBox(height: 12),
          ],
          // 🤰 الحمل
          if (s.pregnancyAlerts.isNotEmpty) ...[
            _alertSection('تحذيرات الحمل', s.pregnancyAlerts,
                Icons.pregnant_woman, Colors.orange),
            const SizedBox(height: 12),
          ],
          // 👶 العمر
          if (s.ageSpecificAlerts.isNotEmpty) ...[
            _alertSection('تنبيهات حسب العمر', s.ageSpecificAlerts,
                Icons.child_care, Colors.blue),
            const SizedBox(height: 12),
          ],
          // 🩺 العلامات الحيوية
          if (s.vitalsWarnings.isNotEmpty) ...[
            _alertSection('العلامات الحيوية', s.vitalsWarnings,
                Icons.monitor_heart, Colors.purple),
            const SizedBox(height: 12),
          ],
          // ⚕️ ملاحظات سريرية
          if (s.clinicalSafetyNotes.isNotEmpty) ...[
            _alertSection('ملاحظات سريرية', s.clinicalSafetyNotes,
                Icons.medical_information_outlined, Colors.teal),
            const SizedBox(height: 12),
          ],
          // 💊 جرعات
          if (s.weightAdjustedNote != null) ...[
            _tipCard('جرعات معدلة بالوزن', s.weightAdjustedNote!),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          _actionButtons(context),
        ],
      ),
    );
  }

  // ─── رأس القسم مع عداد ────────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color, int count) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 6),
      Text(title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Text('$count',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  // ─── بطاقة تفاعل الأدوية الغنية ──────────────────────────────────────────
  Widget _interactionCard(DrugInteractionWarning w) {
    final (bgColor, borderColor) = switch (w.severity) {
      'Critical' => (Colors.red.shade50, Colors.red),
      'High' => (Colors.orange.shade50, Colors.orange),
      'Moderate' => (Colors.amber.shade50, Colors.amber.shade700),
      _ => (Colors.blue.shade50, Colors.blue),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // رأس — اسم التجاري → العلمي
        Row(children: [
          Text(w.severityIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text('${w.drug1} + ${w.drug2}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: borderColor)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(w.severity,
                style: TextStyle(
                    fontSize: 10, color: borderColor, fontWeight: FontWeight.bold)),
          ),
        ]),
        // الاسم العلمي إذا اختلف
        if (w.drug1Generic != w.drug1.toLowerCase() ||
            w.drug2Generic != w.drug2.toLowerCase())
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 28),
            child: Text('(${w.drug1Generic} + ${w.drug2Generic})',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ),
        const Divider(height: 12),
        Text(w.description, style: const TextStyle(fontSize: 12, height: 1.4)),
        const SizedBox(height: 6),
        // التوصية
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 ', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Text(w.recommendation,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade800,
                      fontStyle: FontStyle.italic)),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─── بطاقة تقييم المخاطر ──────────────────────────────────────────────────
  Widget _riskCard(PatientRiskAssessment risk) {
    final color = switch (risk.riskLevel) {
      'حرج جداً' => Colors.red,
      'مرتفع جداً' => Colors.deepOrange,
      'مرتفع' => Colors.orange,
      'معتدل' => Colors.blue,
      _ => Colors.green,
    };
    return Card(
      elevation: 6,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('تقييم المخاطر الكلي',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(20)),
              child: Text('${risk.riskScore}/100',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: risk.riskScore / 100,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('المستوى: ${risk.riskLevel}',
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          if (risk.riskFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: risk.riskFactors
                  .take(4)
                  .map((f) => Chip(
                        label: Text(f, style: const TextStyle(fontSize: 10)),
                        backgroundColor: color.withValues(alpha: 0.1),
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text('المراجعة: ${risk.estimatedReviewFrequency}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ]),
        ]),
      ),
    );
  }

  // ─── قسم تنبيهات نصية ────────────────────────────────────────────────────
  Widget _alertSection(
      String title, List<String> alerts, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.35))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ]),
          const Divider(height: 10),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('▸', style: TextStyle(color: color, fontSize: 13)),
                const SizedBox(width: 6),
                Expanded(child: Text(a, style: const TextStyle(fontSize: 12, height: 1.4))),
              ]),
            ),
        ]),
      ),
    );
  }

  // ─── بطاقة جرعة ──────────────────────────────────────────────────────────
  Widget _tipCard(String title, String content) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.blue.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calculate_outlined, color: Colors.blue, size: 17),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
          ]),
          const Divider(height: 10),
          Text(content, style: const TextStyle(fontSize: 12, height: 1.5)),
        ]),
      ),
    );
  }

  // ─── الأزرار ─────────────────────────────────────────────────────────────
  Widget _actionButtons(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ تم قبول الوصفة'),
              backgroundColor: Colors.green,
            ));
          },
          icon: const Icon(Icons.check),
          label: const Text('قبول الوصفة'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('إلغاء'),
        ),
      ),
    ]);
  }
}
