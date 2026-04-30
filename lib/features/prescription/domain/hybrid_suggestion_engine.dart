import '../data/treatment_protocols.dart';
import '../data/doctor_patterns_repository.dart';

import 'services/dynamic_medical_intelligence_service.dart';
import 'medical_entity_resolver.dart';


// 🏥 نتيجة التوصيات الذكية المتقدمة
class HybridSuggestionResult {
  final List<TreatmentProtocol> staticProtocols;
  final List<DoctorPattern> learnedSuggestions;
  final List<String> vitalsWarnings;
  final List<String> clinicalSafetyNotes;
  final List<DrugInteractionWarning> drugInteractionAlerts; // 🆕 كائنات غنية بالبيانات
  final List<String> allergyAlerts;
  final List<String> ageSpecificAlerts;
  final List<String> pregnancyAlerts;
  final String? weightAdjustedNote;
  final int riskScore;
  final String riskLevel;

  HybridSuggestionResult({
    required this.staticProtocols,
    required this.learnedSuggestions,
    required this.vitalsWarnings,
    required this.clinicalSafetyNotes,
    this.drugInteractionAlerts = const [],
    this.allergyAlerts = const [],
    this.ageSpecificAlerts = const [],
    this.pregnancyAlerts = const [],
    this.weightAdjustedNote,
    this.riskScore = 0,
    this.riskLevel = 'Low',
  });

  /// جميع تحذيرات الأدوية كنصوص
  List<String> get drugInteractionStrings =>
      drugInteractionAlerts.map((w) => w.toString()).toList();

  /// التحذيرات الحرجة فقط (Critical + High)
  List<String> get allCriticalAlerts => [
        ...drugInteractionAlerts
            .where((w) => w.isCritical || w.isHigh)
            .map((w) => w.toString()),
        ...allergyAlerts,
        ...pregnancyAlerts,
        if (riskLevel == 'Critical') ...vitalsWarnings,
      ];

  /// هل يوجد تحذير حرج يستلزم انتباهاً فورياً؟
  bool get hasCriticalAlert =>
      drugInteractionAlerts.any((w) => w.isCritical) ||
      allergyAlerts.isNotEmpty ||
      pregnancyAlerts.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// 🧠 محرك الذكاء الطبي المتقدم الهجين - النسخة الجذرية
// يستخدم MedicalEntityResolver للبحث الدلالي بدلاً من مطابقة النصوص
// ─────────────────────────────────────────────────────────────────────────────
class HybridSuggestionEngine {
  final DynamicMedicalIntelligenceService _dynamicService;

  static final Map<String, HybridSuggestionResult> _inferenceCache = {};
  static const int _maxCacheSize = 100;

  HybridSuggestionEngine(this._dynamicService);


  Future<HybridSuggestionResult> getSuggestions({
    required String diagnosis,
    required String speciality,
    double? systolic,
    double? diastolic,
    double? sugar,
    double? weight,
    int? patientAge,
    int? ageCategory,
    bool? isPregnant,
    String? allergies,
    String? chronicDiseases,
    List<String>? currentMedicines,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '${diagnosis}_${speciality}_${systolic}_${diastolic}_${sugar}_${weight}_${patientAge}_${isPregnant}_${currentMedicines?.join(",")}';

    if (!forceRefresh && _inferenceCache.containsKey(cacheKey)) {
      return _inferenceCache[cacheKey]!;
    }

    final protocols = TreatmentProtocolsDB.search(diagnosis, speciality);
    
    // جلب الأنماط المتعلمة من القاعدة الديناميكية
    final patternMaps = await _dynamicService.getSuggestedTreatments(diagnosis);
    final patterns = patternMaps.map((p) => DoctorPattern(
      diagnosis: p['diagnosis'],
      medicineName: p['medicine_name'],
      dosage: p['dosage'],
      frequency: p['frequency'],
      duration: p['duration'],
      useCount: p['use_count'] ?? 1,
      lastUsed: p['last_used'] != null ? DateTime.parse(p['last_used']) : DateTime.now(),
    )).toList();



    final warnings = <String>[];
    final clinicalNotes = <String>[];
    final allergyAlerts = <String>[];
    final ageSpecificAlerts = <String>[];
    final pregnancyAlerts = <String>[];
    String? weightNote;
    int riskScore = 0;
    final diagLower = diagnosis.toLowerCase();

    // ═══════════════════════════════════════════════════════════════
    // 🔬 فحص التفاعلات بالمترجم الطبي الذكي (Semantic Drug Check)
    // ═══════════════════════════════════════════════════════════════
    List<DrugInteractionWarning> drugInteractionAlerts = [];
    if (currentMedicines != null && currentMedicines.isNotEmpty) {
      // استخدام الخدمة الديناميكية لفحص التفاعلات (دقة وسرعة وبدون حدود)
      final interactionMaps = await _dynamicService.checkInteractions(currentMedicines);
      
      for (final i in interactionMaps) {
        final severity = i['severity'] == 0 ? 'Low' : i['severity'] == 1 ? 'Moderate' : i['severity'] == 2 ? 'High' : 'Critical';
        drugInteractionAlerts.add(DrugInteractionWarning(
          drug1: i['drug1'],
          drug2: i['drug2'],
          drug1Generic: i['drug1'], // في القاعدة الديناميكية نخزن العلمية
          drug2Generic: i['drug2'],
          severity: severity,
          description: i['interaction_description'],
          recommendation: i['recommendation'],
        ));

        switch (severity) {
          case 'Critical': riskScore += 25; break;
          case 'High':     riskScore += 15; break;
          case 'Moderate': riskScore += 8;  break;
          default:         riskScore += 3;
        }
      }
    }


    // ═══════════════════════════════════════════════════════════════
    // 🔴 فحص الحساسيات دلالياً
    // ═══════════════════════════════════════════════════════════════
    if (allergies != null && allergies.isNotEmpty && currentMedicines != null) {
      final conflicts =
          MedicalEntityResolver.checkAllergyConflicts(allergies, currentMedicines);
      allergyAlerts.addAll(conflicts);
      riskScore += conflicts.length * 20;
    }

    // ═══════════════════════════════════════════════════════════════
    // 🤰 فحص الحمل دلالياً
    // ═══════════════════════════════════════════════════════════════
    if (isPregnant == true) {
      if (currentMedicines != null) {
        for (final med in currentMedicines) {
          if (await MedicalEntityResolver.isContraindicatedInPregnancyDynamic(med, _dynamicService)) {
            final generic = await _dynamicService.resolveDrugName(med);
            pregnancyAlerts.add(
                '🚨 حرج - الحمل: $med ($generic) محظور تماماً أثناء الحمل!');
            riskScore += 25;
          }
        }
      }

      if (diagLower.contains('infection') ||
          diagLower.contains('عدوى') ||
          diagLower.contains('التهاب')) {
        pregnancyAlerts.add(
            '⚠️ للحامل: اختر المضادات الحيوية الآمنة فقط: Amoxicillin أو Cephalosporin');
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // 👶 تنبيهات الفئة العمرية
    // ═══════════════════════════════════════════════════════════════
    if (patientAge != null || ageCategory != null) {
      final ageAlerts =
          _getAgeSpecificAlerts(diagLower, patientAge, ageCategory, weight);
      ageSpecificAlerts.addAll(ageAlerts);
      riskScore += ageAlerts.length * 8;
    }

    // ═══════════════════════════════════════════════════════════════
    // 🫀 الأمراض المزمنة
    // ═══════════════════════════════════════════════════════════════
    if (chronicDiseases != null && chronicDiseases.isNotEmpty) {
      final chronicAlerts = _getChronicDiseaseAlerts(
          diagLower, chronicDiseases, systolic, diastolic, sugar);
      warnings.addAll(chronicAlerts);
      riskScore += chronicAlerts.length * 12;
    }

    // ═══════════════════════════════════════════════════════════════
    // 🩺 المؤشرات الحيوية الحرجة
    // ═══════════════════════════════════════════════════════════════
    _checkVitals(systolic, diastolic, sugar, diagLower, warnings);

    // ═══════════════════════════════════════════════════════════════
    // ⚕️ ملاحظات سريرية عامة
    // ═══════════════════════════════════════════════════════════════
    if (diagLower.contains('kidney') ||
        diagLower.contains('كلى') ||
        diagLower.contains('renal')) {
      clinicalNotes.add(
          '⚙️ الكلى: تأكد من تعديل الجرعات وفقاً لـ eGFR قبل الوصف.');
    }
    if (diagLower.contains('liver') ||
        diagLower.contains('كبد') ||
        diagLower.contains('hepatic')) {
      clinicalNotes.add(
          '🔴 الكبد: تجنب الباراسيتامول بجرعات عالية والستاتينات في القصور الكبدي.');
    }

    // ═══════════════════════════════════════════════════════════════
    // 💊 حساب الجرعات بالوزن
    // ═══════════════════════════════════════════════════════════════
    if (weight != null && weight > 0) {
      weightNote = _calculateAdjustedDoses(weight, patientAge, ageCategory);
    }

    // تحديد مستوى الخطورة
    final String riskLevel;
    if (riskScore >= 80) {
      riskLevel = 'Critical';
    } else if (riskScore >= 50) {
      riskLevel = 'High';
    } else if (riskScore >= 25) {
      riskLevel = 'Moderate';
    } else {
      riskLevel = 'Low';
    }

    final result = HybridSuggestionResult(
      staticProtocols: protocols,
      learnedSuggestions: patterns,
      vitalsWarnings: warnings,
      clinicalSafetyNotes: clinicalNotes,
      drugInteractionAlerts: drugInteractionAlerts,
      allergyAlerts: allergyAlerts,
      ageSpecificAlerts: ageSpecificAlerts,
      pregnancyAlerts: pregnancyAlerts,
      weightAdjustedNote: weightNote,
      riskScore: riskScore.clamp(0, 100),
      riskLevel: riskLevel,
    );

    if (_inferenceCache.length >= _maxCacheSize) _inferenceCache.clear();
    _inferenceCache[cacheKey] = result;
    return result;
  }

  void _checkVitals(double? systolic, double? diastolic, double? sugar,
      String diagLower, List<String> warnings) {
    if (systolic != null) {
      if (systolic >= 180) {
        warnings.add(
            '🚨 أزمة ضغط الدم (${systolic.toInt()} mmHg): تدخل طارئ فوري!');
      } else if (systolic >= 160) {
        warnings.add(
            '🔴 ضغط مرتفع جداً (${systolic.toInt()} mmHg): تشاور طبي فوري');
      } else if (systolic >= 140) {
        if (diagLower.contains('pain') ||
            diagLower.contains('ألم') ||
            diagLower.contains('arthritis')) {
          warnings.add(
              '⚠️ ضغط مرتفع مع ألم: تجنب NSAIDs - استخدم الباراسيتامول فقط');
        }
      }
    }
    if (sugar != null) {
      if (sugar > 400) {
        warnings.add(
            '🚨 سكر خطير جداً (${sugar.toInt()} mg/dL): أرسل المريض للطوارئ!');
      } else if (sugar > 300) {
        warnings.add(
            '🔴 سكر مرتفع جداً (${sugar.toInt()} mg/dL): تقييم طارئ مطلوب');
      } else if (sugar > 200) {
        if (diagLower.contains('inflammation') ||
            diagLower.contains('التهاب')) {
          warnings.add(
              '⚠️ سكر مرتفع مع التهاب: الستيرويدات ستزيد السكر - فكر في البديل');
        }
      }
    }
  }

  List<String> _getAgeSpecificAlerts(String diagnosis, int? patientAge,
      int? ageCategory, double? weight) {
    final alerts = <String>[];
    final isPediatric =
        ageCategory == 0 || (patientAge != null && patientAge < 5);
    final isChild =
        ageCategory == 1 || (patientAge != null && patientAge < 12);
    final isElderly = ageCategory == 3 ||
        ageCategory == 4 ||
        (patientAge != null && patientAge >= 65);

    if (isPediatric || isChild) {
      alerts.add(
          '👶 الأطفال: احسب الجرعة بالوزن (mg/kg) وتأكد من صيغة شراب/قطرات');
      if (weight != null) {
        final paraDose = (weight * 15).round();
        final amoxDose = (weight * 40).round();
        alerts.add('💊 جرعات محسوبة للوزن ${weight.toStringAsFixed(1)} كغ:\n'
            '   • باراسيتامول: $paraDose ملغ / 6 ساعات\n'
            '   • أموكسيسيلين: $amoxDose ملغ / 8 ساعات');
      }
    }
    if (isElderly) {
      alerts.add('👴 كبار السن: ابدأ بجرعة 50% أقل (Start Low, Go Slow)');
      alerts.add('🔍 افحص eGFR قبل وصف الأدوية المطروحة كلوياً');
      if (diagnosis.contains('sleep') ||
          diagnosis.contains('نوم') ||
          diagnosis.contains('anxiety') ||
          diagnosis.contains('قلق')) {
        alerts.add(
            '🚨 Beers: تجنب البنزوديازيبينات وأدوية النوم طويلة المفعول في المسنين');
      }
    }
    return alerts;
  }

  List<String> _getChronicDiseaseAlerts(String diagnosis, String chronicDiseases,
      double? systolic, double? diastolic, double? sugar) {
    final alerts = <String>[];
    final c = chronicDiseases.toLowerCase();

    if (c.contains('diabetes') || c.contains('سكري')) {
      alerts.add('🩸 سكري: راقب تأثير الستيرويدات والمدرات على السكر');
      if (sugar != null && sugar > 200) {
        alerts.add('🚨 سكر مرتفع + سكري: تنسيق ضروري قبل وصف الستيرويدات');
      }
    }
    if (c.contains('hypertension') || c.contains('ضغط')) {
      alerts.add('🫀 ضغط الدم: تجنب NSAIDs تماماً، استخدم الباراسيتامول');
      if (systolic != null && systolic >= 160) {
        alerts.add('🚨 ضغط غير متحكم (${systolic.toInt()}/${diastolic?.toInt() ?? '?'}): راجع خطة العلاج');
      }
    }
    if (c.contains('kidney') || c.contains('كلى') || c.contains('renal')) {
      alerts.add('⚙️ كلى: اضبط الجرعات حسب eGFR وتجنب NSAIDs والـ Gentamicin');
    }
    if (c.contains('liver') || c.contains('كبد')) {
      alerts.add('🔴 كبد: الباراسيتامول ≤ 2000 ملغ/يوم، تجنب الستاتينات');
    }
    if (c.contains('asthma') || c.contains('ربو')) {
      alerts.add('🫁 ربو: تجنب الأسبرين والـ NSAIDs (تسبب تشنجاً في 20% من الحالات)');
    }
    return alerts;
  }

  String _calculateAdjustedDoses(
      double weight, int? patientAge, int? ageCategory) {
    final buf = StringBuffer(
        '💡 جرعات معدلة للوزن ${weight.toStringAsFixed(1)} كغ:\n');
    buf.writeln('• باراسيتامول: ${(weight * 10).round()}–${(weight * 15).round()} ملغ كل 6 ساعات');
    if (ageCategory == null || ageCategory >= 1) {
      buf.writeln('• إيبوبروفين: ${(weight * 10).round()} ملغ كل 8 ساعات');
    }
    buf.writeln('• أموكسيسيلين: ${(weight * 40).round()}–${(weight * 50).round()} ملغ كل 8 ساعات');
    buf.writeln('• أزيثرومايسين: ${(weight * 10).round()} ملغ اليوم الأول');
    return buf.toString();
  }

  static void clearCache() => _inferenceCache.clear();
}
