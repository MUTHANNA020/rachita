import 'dart:convert';
import '../../features/prescription/domain/entities/prescription_entity.dart';

import '../../features/patient/domain/entities/patient_entity.dart';
import '../../features/prescription/domain/services/dynamic_medical_intelligence_service.dart';
import '../../features/prescription/domain/medical_entity_resolver.dart';
import '../../features/prescription/domain/services/drug_interaction_service.dart' as di_service;

/// 🧠 محرك الاستنتاج السريري - Clinical Reasoning Engine (CRE)
/// 
/// يمثل "عقل" النظام؛ حيث لا يكتفي بمطابقة النصوص، بل يقوم بالاستنتاج المنطقي
/// بناءً على الحالة السريرية الكاملة للمريض.
class ClinicalReasoningEngine {
  final DynamicMedicalIntelligenceService _dynamicService;

  ClinicalReasoningEngine(this._dynamicService);

  /// إجراء تحليل سريري شامل للحالة
  Future<ClinicalInferenceResult> analyzeSituation({
    required PatientEntity patient,
    required String currentDiagnosis,
    required List<String> prescribedMedicines,
    Map<String, double>? vitals,
  }) async {
    final insights = <ClinicalInsight>[];
    int confidenceScore = 100;

    // 1. استنتاج بناءً على المؤشرات الحيوية (Vital-Based Reasoning)
    if (vitals != null) {
      final systolic = vitals['systolic'];
      final sugar = vitals['sugar'];

      if (systolic != null && systolic > 140) {
        if (prescribedMedicines.any((m) => m.toLowerCase().contains('nsaid') || m.toLowerCase().contains('diclofenac'))) {
          insights.add(ClinicalInsight(
            title: 'تعارض ضغط الدم مع المسكنات',
            explanation: 'المريض يعاني من ارتفاع ضغط الدم (${systolic.toInt()}). الـ NSAIDs ترفع الضغط وتؤثر على الكلى.',
            recommendation: 'استبدل المسكن بـ Paracetamol 1g.',
            severity: InsightSeverity.high,
          ));
          confidenceScore -= 20;
        }
      }
      
      if (sugar != null && sugar > 200) {
        if (prescribedMedicines.any((m) => m.toLowerCase().contains('dexa') || m.toLowerCase().contains('prednisone'))) {
          insights.add(ClinicalInsight(
            title: 'خطر ارتفاع السكر الحاد',
            explanation: 'وصف الستيرويدات لمريض سكر مرتفع (${sugar.toInt()}) قد يؤدي إلى Hyperglycemic Crisis.',
            recommendation: 'راجع ضرورة الستيرويدات أو عدل خطة الأنسولين.',
            severity: InsightSeverity.critical,
          ));
          confidenceScore -= 30;
        }
      }
    }

    // 2. استنتاج دلالي للأدوية (Semantic Drug Reasoning)
    // ندمج الأدوية الجديدة مع الأدوية الحالية للمريض لفحص التفاعلات
    final allMeds = [...prescribedMedicines];
    try {
      final currentMeds = (jsonDecode(patient.currentMedicationsJson) as List)
          .map((m) => (m['name'] ?? m['medicineName'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
      allMeds.addAll(currentMeds);
    } catch (_) {}

    for (var med in prescribedMedicines) {
      final generic = await _dynamicService.resolveDrugName(med);
      final interactionService = di_service.DrugInteractionService();
      
      // فحص التفاعلات مع الأدوية الحالية (Drug-Drug Interaction) عبر الدماغ الطبي (قاعدة البيانات)
      for (var existingMed in allMeds) {
        if (med == existingMed) continue;
        
        final interaction = await interactionService.checkInteraction(med, existingMed);
        
        if (interaction.hasInteraction) {
          insights.add(ClinicalInsight(
            title: interaction.isCritical ? 'تفاعل دوائي حرج!' : 'تنبيه تفاعل دوائي',
            explanation: interaction.description ?? 'يوجد تعارض سريري بين $med و $existingMed.',
            recommendation: interaction.recommendation ?? 'يرجى مراجعة الوصفة.',
            severity: interaction.isCritical 
                ? InsightSeverity.critical 
                : interaction.isHigh ? InsightSeverity.high : InsightSeverity.warning,
          ));
        }
      }

      if (patient.isPregnant == true) {
        if (await MedicalEntityResolver.isContraindicatedInPregnancyDynamic(med, _dynamicService)) {
          insights.add(ClinicalInsight(
            title: 'خطورة جنينية (Teratogenic Risk)',
            explanation: 'دواء $med ($generic) محظور تماماً في الحمل.',
            recommendation: 'أوقف الدواء فوراً واستبدله ببدائل فئة A/B.',
            severity: InsightSeverity.critical,
          ));
          confidenceScore -= 40;
        }
      }

      // فحص الحساسيات المتصالبة (Cross-Sensitivity)
      if (patient.allergies != null && patient.allergies!.isNotEmpty) {
        if (patient.allergies!.toLowerCase().contains('penicillin') && 
            (generic.toLowerCase().contains('amoxicillin') || generic.toLowerCase().contains('cefalexin'))) {
          insights.add(ClinicalInsight(
            title: 'حساسية متصالبة (Cross-Allergy)',
            explanation: 'المريض لديه حساسية بنسلين؛ الـ $med ينتمي لنفس العائلة الكيميائية.',
            recommendation: 'استبدل بـ Azithromycin أو Clarithromycin.',
            severity: InsightSeverity.high,
          ));
          confidenceScore -= 25;
        }
      }
    }

    // 3. ذكاء التنبؤ بالجرعات (Dosage Intelligence)
    final weight = vitals?['weight'];
    if (patient.age != null && patient.age! < 12 && weight != null) {
      insights.add(ClinicalInsight(
        title: 'تعديل جرعة الأطفال',
        explanation: 'بناءً على وزن الطفل ($weight كغ)، الجرعة المثالية يتم حسابها ديناميكياً.',
        recommendation: 'تأكد من استخدام قاعدة mg/kg.',

        severity: InsightSeverity.info,
      ));
    }

    return ClinicalInferenceResult(
      insights: insights,
      confidenceScore: confidenceScore.clamp(0, 100),
      status: insights.any((i) => i.severity == InsightSeverity.critical) 
          ? 'خطر مرتفع' 
          : (insights.isEmpty ? 'حالة مستقرة' : 'تنبيهات هامة'),
    );
  }
}

enum InsightSeverity { info, warning, high, critical }

class ClinicalInsight {
  final String title;
  final String explanation;
  final String recommendation;
  final InsightSeverity severity;

  ClinicalInsight({
    required this.title,
    required this.explanation,
    required this.recommendation,
    required this.severity,
  });
}

class ClinicalInferenceResult {
  final List<ClinicalInsight> insights;
  final int confidenceScore;
  final String status;

  ClinicalInferenceResult({
    required this.insights,
    required this.confidenceScore,
    required this.status,
  });
}
