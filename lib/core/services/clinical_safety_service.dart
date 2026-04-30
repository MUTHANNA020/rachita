import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/clinical_logic.dart';
import '../../features/prescription/domain/entities/prescription_entity.dart';
import '../../features/patient/presentation/providers/patient_provider.dart';
import '../../features/prescription/presentation/providers/prescription_provider.dart';
import '../../features/prescription/domain/services/drug_interaction_service.dart';
import '../../features/prescription/domain/medical_entity_resolver.dart';

class SafetyReport {
  final List<String> warnings;
  final List<String> errors;
  final int riskScore;

  SafetyReport({
    this.warnings = const [],
    this.errors = const [],
    this.riskScore = 0,
  });

  bool get hasIssues => warnings.isNotEmpty || errors.isNotEmpty;
  bool get isHighRisk => riskScore >= 5 || errors.isNotEmpty;
}

final safetyReportProvider = Provider<SafetyReport>((ref) {
  final prescription = ref.watch(currentPrescriptionProvider);
  if (prescription == null) return SafetyReport();

  final patientAsync = ref.watch(patientByIdProvider(prescription.patientId));

  return patientAsync.when(
    data: (patient) {
      if (patient == null) return SafetyReport();

      final warnings = <String>[];
      final errors = <String>[];
      final service = DrugInteractionService();

      // ─── 1. فحص الحساسية الكاملة (مع الأسماء التجارية والعلمية) ───────────────
      if (prescription.medicines != null) {
        for (final med in prescription.medicines!) {
          // أ) فحص الحساسية عبر MedicalEntityResolver
          final allergyAlerts = MedicalEntityResolver.checkAllergyConflicts(
            patient.allergies ?? '',
            [med.medicineName],
          );
          for (final alert in allergyAlerts) {
            errors.add(alert);
          }

          // ب) فحص الأدوية المحظورة على الحوامل
          if (patient.isPregnant) {
            if (MedicalEntityResolver.isContraindicatedInPregnancy(
                med.medicineName)) {
              final generic =
                  MedicalEntityResolver.resolve(med.medicineName);
              errors.add(
                  '🚫 خطر جنيني: ${med.medicineName} ($generic) محظور في الحمل!');
            }
          }
        }
      }

      // ─── 2. فحص التفاعلات الدوائية الكامل (مع الأدوية الحالية للمريض) ─────────
      if (prescription.medicines != null &&
          prescription.medicines!.length >= 2) {
        final newMedNames =
            prescription.medicines!.map((m) => m.medicineName).toList();

        // إضافة الأدوية الحالية للمريض من سجله
        final allMeds = [...newMedNames];
        try {
          final currentMeds =
              (jsonDecode(patient.currentMedicationsJson) as List)
                  .map(
                      (m) => (m['name'] ?? m['medicineName'] ?? '').toString())
                  .where((n) => n.isNotEmpty)
                  .toList();
          allMeds.addAll(currentMeds);
        } catch (_) {}

        // فحص التفاعلات بين كل الأدوية
        final interactions = service.checkMultipleInteractions(allMeds);
        for (final interaction in interactions) {
          if (interaction.severity == InteractionSeverity.critical) {
            errors.add(
                '${interaction.drug1} ↔ ${interaction.drug2}: ${interaction.description ?? "تفاعل حرج"}');
          } else if (interaction.severity == InteractionSeverity.high) {
            warnings.add(
                '${interaction.drug1} ↔ ${interaction.drug2}: ${interaction.description ?? "تفاعل مرتفع"}');
          } else if (interaction.severity == InteractionSeverity.moderate) {
            warnings.add(
                '${interaction.drug1} + ${interaction.drug2}: ${interaction.description ?? "تفاعل معتدل"}');
          }
        }
      }

      // ─── 3. فحص المؤشرات الحيوية الحرجة ──────────────────────────────────────
      final riskScore = ClinicalLogic.calculateVitalsRisk(
        prescription.systolic,
        prescription.diastolic,
        prescription.temperature,
        prescription.pulse,
      );

      if (prescription.systolic != null && prescription.systolic! >= 180) {
        errors.add('🚨 أزمة ضغط دم: ${prescription.systolic}/${prescription.diastolic} — يتطلب تدخلاً فورياً!');
      } else if (prescription.systolic != null && prescription.systolic! >= 160) {
        warnings.add('⚠️ ضغط الدم مرتفع جداً (${prescription.systolic}) — راجع الدواء.');
      }

      if (prescription.sugar != null && prescription.sugar! >= 300) {
        errors.add('🚨 سكر حرج: ${prescription.sugar!.toInt()} mg/dL — خطر Hyperglycemic Crisis!');
      } else if (prescription.sugar != null && prescription.sugar! >= 200) {
        warnings.add('⚠️ ارتفاع سكر الدم: ${prescription.sugar!.toInt()} mg/dL.');
      }

      if (prescription.temperature != null && prescription.temperature! >= 39.5) {
        warnings.add('🌡️ حرارة مرتفعة جداً: ${prescription.temperature}°C — تأكد من تغطية المضادات الحيوية.');
      }

      // ─── 4. فحص Renal/Hepatic Dosing ───────────────────────────────────────
      final chronicLower = (patient.chronicDiseases ?? '').toLowerCase();
      if (prescription.medicines != null) {
        for (final med in prescription.medicines!) {
          final generic = MedicalEntityResolver.resolve(med.medicineName).toLowerCase();

          // مرضى الكلى — أدوية تُطرح كلوياً
          if (chronicLower.contains('كلى') ||
              chronicLower.contains('kidney') ||
              chronicLower.contains('renal')) {
            const renalRisk = [
              'metformin', 'nsaid', 'ibuprofen', 'diclofenac',
              'naproxen', 'ciprofloxacin', 'vancomycin', 'gentamicin'
            ];
            if (renalRisk.any((r) => generic.contains(r))) {
              warnings.add('🫘 تحذير كلوي: ${med.medicineName} يتطلب تعديل جرعة أو إيقاف عند القصور الكلوي.');
            }
          }

          // مرضى الكبد — أدوية تتحلل كبدياً
          if (chronicLower.contains('كبد') ||
              chronicLower.contains('liver') ||
              chronicLower.contains('hepatic')) {
            const hepaticRisk = [
              'paracetamol', 'acetaminophen', 'methotrexate', 'statins',
              'atorvastatin', 'simvastatin', 'isoniazid', 'rifampicin'
            ];
            if (hepaticRisk.any((r) => generic.contains(r))) {
              warnings.add('🫁 تحذير كبدي: ${med.medicineName} يستلزم تعديل الجرعة أو رصد وظائف الكبد.');
            }
          }

          // كبار السن — تقليل الجرعات
          if (patient.age != null && patient.age! >= 75) {
            warnings.add('👴 مريض كبير السن (${patient.age} سنة): راجع جرعة ${med.medicineName} — تقليل 25-50% قد يكون مطلوباً.');
            break; // تنبيه واحد يكفي لكبار السن
          }
        }
      }

      return SafetyReport(
        warnings: warnings,
        errors: errors,
        riskScore: riskScore,
      );
    },
    loading: () => SafetyReport(),
    error: (_, __) => SafetyReport(),
  );
});
