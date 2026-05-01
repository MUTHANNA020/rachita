import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/clinical_alert_service.dart';
import '../../domain/services/drug_interaction_service.dart';
import '../../domain/services/risk_assessment_service.dart';
import '../../domain/hybrid_suggestion_engine.dart';
import '../../data/doctor_patterns_repository.dart';
import '../../domain/services/dynamic_medical_intelligence_service.dart';
import '../../../../core/services/clinical_reasoning_engine.dart';





import '../../../../core/services/smart_voice_command_service.dart';

// ============================================
// 🏥 Riverpod Providers للخدمات الطبية
// ============================================

/// 🔔 Provider لخدمة التنبيهات السريرية
final clinicalAlertServiceProvider = Provider<ClinicalAlertService>((ref) {
  return ClinicalAlertService();
});

/// 💊 Provider لخدمة فحص تفاعلات الأدوية
final drugInteractionServiceProvider = Provider<DrugInteractionService>((ref) {
  return DrugInteractionService();
});

/// 📊 Provider لخدمة تقييم المخاطر
final riskAssessmentServiceProvider = Provider<RiskAssessmentService>((ref) {
  return RiskAssessmentService();
});

/// 🧠 Provider للخدمة الديناميكية
final dynamicClinicalServiceProvider = Provider<DynamicMedicalIntelligenceService>((ref) {
  return DynamicMedicalIntelligenceService();
});

/// 🧠 Provider لمحرك الاستنتاج السريري (العقل المدبر)
final clinicalReasoningEngineProvider = Provider<ClinicalReasoningEngine>((ref) {
  final dynamicService = ref.watch(dynamicClinicalServiceProvider);
  return ClinicalReasoningEngine(dynamicService);
});

/// 🧠 Provider لمحرك الذكاء الطبي الهجين
final hybridSuggestionEngineProvider = Provider<HybridSuggestionEngine>((ref) {
  final dynamicService = ref.watch(dynamicClinicalServiceProvider);
  return HybridSuggestionEngine(dynamicService);
});

/// 🎙️ Provider لمحرك الأوامر الصوتية الذكية
final smartVoiceCommandServiceProvider = Provider<SmartVoiceCommandService>((ref) {
  final dynamicService = ref.watch(dynamicClinicalServiceProvider);
  return SmartVoiceCommandService(dynamicService);
});



// ============================================
// 🎯 Providers لنتائج التقييمات
// ============================================

/// 📋 StateNotifier للتنبيهات السريرية
class ClinicalAlertsNotifier extends StateNotifier<List<ClinicalAlert>> {
  final ClinicalAlertService _service;

  ClinicalAlertsNotifier(this._service) : super([]);

  void addAlert(ClinicalAlert alert) {
    _service.addAlert(alert);
    state = _service.getAlerts();
  }

  void removeAlert(ClinicalAlert alert) {
    _service.removeAlert(alert);
    state = _service.getAlerts();
  }

  void resolveAlert(ClinicalAlert alert, String? notes) {
    _service.resolveAlert(alert, notes);
    state = _service.getAlerts();
  }

  void clearResolved() {
    _service.clearResolvedAlerts();
    state = _service.getAlerts();
  }

  List<ClinicalAlert> getUnresolvedAlerts() {
    return state.where((alert) => !alert.isResolved).toList();
  }

  List<ClinicalAlert> getCriticalAlerts() {
    return state
        .where((alert) => alert.isCritical && !alert.isResolved)
        .toList();
  }
}

final clinicalAlertsProvider =
    StateNotifierProvider<ClinicalAlertsNotifier, List<ClinicalAlert>>((ref) {
  final service = ref.watch(clinicalAlertServiceProvider);
  return ClinicalAlertsNotifier(service);
});

// ============================================
// 🧮 Providers للحسابات والتقييمات
// ============================================

/// 💊 فحص تفاعلات الأدوية
final drugInteractionsProvider =
    FutureProvider.family<List<DrugInteractionResult>, List<String>>(
  (ref, medicines) async {
    final service = ref.watch(drugInteractionServiceProvider);
    return service.checkMultipleInteractions(medicines);
  },
);

/// 📊 تقييم مخاطر المريض
final patientRiskAssessmentProvider =
    FutureProvider.family<PatientRiskAssessment, PatientRiskParams>(
  (ref, params) async {
    final service = ref.watch(riskAssessmentServiceProvider);
    return service.assessPatientRisk(
      age: params.age,
      ageCategory: params.ageCategory,
      isPregnant: params.isPregnant,
      chronicDiseases: params.chronicDiseases,
      allergies: params.allergies,
      systolic: params.systolic,
      diastolic: params.diastolic,
      bloodSugar: params.bloodSugar,
      currentMedicines: params.currentMedicines,
    );
  },
);

/// 🧠 التوصيات الذكية الهجينة
final hybridSuggestionsProvider =
    FutureProvider.family<HybridSuggestionResult, HybridSuggestionParams>(
  (ref, params) async {
    final engine = ref.watch(hybridSuggestionEngineProvider);
    return engine.getSuggestions(
      diagnosis: params.diagnosis,
      speciality: params.speciality,
      systolic: params.systolic,
      diastolic: params.diastolic,
      sugar: params.sugar,
      weight: params.weight,
      patientAge: params.patientAge,
      ageCategory: params.ageCategory,
      isPregnant: params.isPregnant,
      allergies: params.allergies,
      chronicDiseases: params.chronicDiseases,
      currentMedicines: params.currentMedicines,
    );
  },
);

/// 🔴 التنبيهات التي تم إنشاؤها من التوصيات
final generatedAlertsProvider =
    FutureProvider.family<List<ClinicalAlert>, GeneratedAlertsParams>(
  (ref, params) async {
    final suggestions = await ref.watch(
      hybridSuggestionsProvider(params.suggestionParams).future,
    );
    final alertService = ref.watch(clinicalAlertServiceProvider);
    return alertService.generateAlertsFromSuggestions(
      suggestions,
      params.patientId,
      params.prescriptionId,
    );
  },
);

// ============================================
// 📊 Providers للإحصائيات
// ============================================

/// 📈 إحصائيات التنبيهات
final alertStatisticsProvider = Provider<AlertStatistics>((ref) {
  final alertService = ref.watch(clinicalAlertServiceProvider);
  return alertService.getStatistics();
});

/// 📉 إحصائيات التفاعلات الدوائية
final interactionStatisticsProvider =
    FutureProvider.family<InteractionStatistics, List<String>>((ref, medicines) async {
  final service = ref.watch(drugInteractionServiceProvider);
  return service.getStatistics(medicines);
});

// ============================================
// 🎯 Helpers Models
// ============================================

/// 📋 معاملات تقييم مخاطر المريض
class PatientRiskParams {
  final int? age;
  final int? ageCategory;
  final bool isPregnant;
  final String? chronicDiseases;
  final String? allergies;
  final double? systolic;
  final double? diastolic;
  final double? bloodSugar;
  final List<String>? currentMedicines;

  PatientRiskParams({
    this.age,
    this.ageCategory,
    this.isPregnant = false,
    this.chronicDiseases,
    this.allergies,
    this.systolic,
    this.diastolic,
    this.bloodSugar,
    this.currentMedicines,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientRiskParams &&
          runtimeType == other.runtimeType &&
          age == other.age &&
          ageCategory == other.ageCategory &&
          isPregnant == other.isPregnant &&
          chronicDiseases == other.chronicDiseases &&
          allergies == other.allergies &&
          systolic == other.systolic &&
          diastolic == other.diastolic &&
          bloodSugar == other.bloodSugar &&
          currentMedicines == other.currentMedicines;

  @override
  int get hashCode => Object.hashAll([
        age,
        ageCategory,
        isPregnant,
        chronicDiseases,
        allergies,
        systolic,
        diastolic,
        bloodSugar,
        currentMedicines,
      ]);
}

/// 🧠 معاملات التوصيات الهجينة
class HybridSuggestionParams {
  final String diagnosis;
  final String speciality;
  final double? systolic;
  final double? diastolic;
  final double? sugar;
  final double? weight;
  final int? patientAge;
  final int? ageCategory;
  final bool? isPregnant;
  final String? allergies;
  final String? chronicDiseases;
  final List<String>? currentMedicines;

  HybridSuggestionParams({
    required this.diagnosis,
    required this.speciality,
    this.systolic,
    this.diastolic,
    this.sugar,
    this.weight,
    this.patientAge,
    this.ageCategory,
    this.isPregnant,
    this.allergies,
    this.chronicDiseases,
    this.currentMedicines,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HybridSuggestionParams &&
          runtimeType == other.runtimeType &&
          diagnosis == other.diagnosis &&
          speciality == other.speciality &&
          systolic == other.systolic &&
          diastolic == other.diastolic &&
          sugar == other.sugar &&
          weight == other.weight &&
          patientAge == other.patientAge &&
          ageCategory == other.ageCategory &&
          isPregnant == other.isPregnant &&
          allergies == other.allergies &&
          chronicDiseases == other.chronicDiseases &&
          currentMedicines == other.currentMedicines;

  @override
  int get hashCode => Object.hashAll([
        diagnosis,
        speciality,
        systolic,
        diastolic,
        sugar,
        weight,
        patientAge,
        ageCategory,
        isPregnant,
        allergies,
        chronicDiseases,
        currentMedicines,
      ]);
}

/// 🔔 معاملات التنبيهات المولدة
class GeneratedAlertsParams {
  final HybridSuggestionParams suggestionParams;
  final String patientId;
  final String prescriptionId;

  GeneratedAlertsParams({
    required this.suggestionParams,
    required this.patientId,
    required this.prescriptionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedAlertsParams &&
          runtimeType == other.runtimeType &&
          suggestionParams == other.suggestionParams &&
          patientId == other.patientId &&
          prescriptionId == other.prescriptionId;

  @override
  int get hashCode => Object.hash(suggestionParams, patientId, prescriptionId);
}
