import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/drug_interaction_service.dart';
import '../../domain/services/risk_assessment_service.dart';
import '../../domain/entities/prescription_medicine_entity.dart';
import '../../../patient/domain/entities/patient_entity.dart';
import 'prescription_provider.dart';
import '../../../patient/presentation/providers/patient_provider.dart';

// ─── Drug Interaction Provider ────────────────────────────────────────────────

final drugInteractionServiceProvider = Provider<DrugInteractionService>((ref) {
  return DrugInteractionService();
});

final riskAssessmentServiceProvider = Provider<RiskAssessmentService>((ref) {
  return RiskAssessmentService();
});

/// Provider يحسب التفاعلات الدوائية لقائمة الأدوية الحالية في الروشتة ديناميكياً من قاعدة البيانات
final liveInteractionCheckProvider = FutureProvider<LiveInteractionReport>((ref) async {
  final prescription = ref.watch(currentPrescriptionProvider);
  if (prescription == null || (prescription.medicines?.isEmpty ?? true)) {
    return LiveInteractionReport.empty();
  }

  final service = ref.read(drugInteractionServiceProvider);
  final medicines = prescription.medicines!.map((m) => m.medicineName).toList();

  // إضافة الأدوية الحالية للمريض إن وُجدت
  final patientAsync = ref.watch(patientByIdProvider(prescription.patientId));
  final allMeds = [...medicines];
  
  if (patientAsync.value != null && patientAsync.value!.currentMedicationsJson.isNotEmpty) {
    try {
      final currentMeds = (jsonDecode(patientAsync.value!.currentMedicationsJson) as List)
          .map((m) => (m['name'] ?? m['medicineName'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList();
      allMeds.addAll(currentMeds);
    } catch (_) {}
  }

  final stats = await service.getStatistics(allMeds);
  return LiveInteractionReport(
    statistics: stats,
    hasCritical: stats.hasCriticalInteractions,
    criticalCount: stats.criticalCount,
    highCount: stats.highCount,
    moderateCount: stats.moderateCount,
    allInteractions: stats.interactions,
  );
});

/// Provider يحسب تقييم مخاطر المريض ديناميكياً بناءً على الوصفة الحالية
final liveRiskAssessmentProvider = Provider<PatientRiskAssessment?>((ref) {
  final prescription = ref.watch(currentPrescriptionProvider);
  if (prescription == null) return null;

  final patientAsync = ref.watch(patientByIdProvider(prescription.patientId));
  return patientAsync.when(
    data: (patient) {
      if (patient == null) return null;
      final service = ref.read(riskAssessmentServiceProvider);

      // بناء قائمة الأدوية الكاملة
      final meds = prescription.medicines?.map((m) => m.medicineName).toList() ?? [];
      try {
        final currentMeds = (jsonDecode(patient.currentMedicationsJson) as List)
            .map((m) => (m['name'] ?? m['medicineName'] ?? '').toString())
            .where((n) => n.isNotEmpty)
            .toList();
        meds.addAll(currentMeds);
      } catch (_) {}

      return service.assessPatientRisk(
        age: patient.age,
        ageCategory: patient.ageCategory,
        isPregnant: patient.isPregnant,
        chronicDiseases: patient.chronicDiseases,
        allergies: patient.allergies,
        systolic: prescription.systolic?.toDouble(),
        diastolic: prescription.diastolic?.toDouble(),
        bloodSugar: prescription.sugar,
        currentMedicines: meds,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ─── نماذج التقرير ─────────────────────────────────────────────────────────

class LiveInteractionReport {
  final InteractionStatistics? statistics;
  final bool hasCritical;
  final int criticalCount;
  final int highCount;
  final int moderateCount;
  final List<DrugInteractionResult> allInteractions;

  const LiveInteractionReport({
    required this.statistics,
    required this.hasCritical,
    required this.criticalCount,
    required this.highCount,
    required this.moderateCount,
    required this.allInteractions,
  });

  factory LiveInteractionReport.empty() => const LiveInteractionReport(
        statistics: null,
        hasCritical: false,
        criticalCount: 0,
        highCount: 0,
        moderateCount: 0,
        allInteractions: [],
      );

  bool get hasAnyIssue => criticalCount > 0 || highCount > 0 || moderateCount > 0;
  int get totalIssues => criticalCount + highCount + moderateCount;
}
