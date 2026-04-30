/// 🏥 خدمة تقييم المخاطر الطبية
class RiskAssessmentService {
  static final RiskAssessmentService _instance =
      RiskAssessmentService._internal();

  factory RiskAssessmentService() {
    return _instance;
  }

  RiskAssessmentService._internal();

  /// 🎯 تقييم المخاطر الشامل للمريض
  PatientRiskAssessment assessPatientRisk({
    required int? age,
    required int?
        ageCategory, // 0:Pediatric, 1:Adolescent, 2:Adult, 3:Geriatric, 4:Elderly
    required bool isPregnant,
    required String? chronicDiseases,
    required String? allergies,
    required double? systolic,
    required double? diastolic,
    required double? bloodSugar,
    required List<String>? currentMedicines,
  }) {
    int riskScore = 0;
    final riskFactors = <String>[];
    final recommendations = <String>[];

    // ========== 📊 تقييم العمر ==========
    if (age != null) {
      if (age < 5 || ageCategory == 0) {
        riskScore += 15;
        riskFactors.add('عمر الطفل (<5 سنوات) - حساسية عالية للأدوية');
        recommendations.add('حسب الجرعات بدقة عالية حسب الوزن');
      } else if (age >= 75 || ageCategory == 4) {
        riskScore += 25;
        riskFactors.add('عمر متقدم جداً (>75) - قصور كلوي وكبدي احتمالي');
        recommendations.add('قلل الجرعات، اختبر وظائف الكلى والكبد');
      } else if (age >= 65 || ageCategory == 3) {
        riskScore += 15;
        riskFactors.add('عمر متقدم (>65) - قصور كلوي محتمل');
        recommendations.add('افحص وظائف الكلى بانتظام');
      }
    }

    // ========== 🤰 تقييم الحمل ==========
    if (isPregnant) {
      riskScore += 30;
      riskFactors.add('حالة الحمل - خطر على الجنين');
      recommendations.add('تجنب الأدوية المحظورة، استخدم الفئة A/B من FDA');
    }

    // ========== 🫀 تقييم ضغط الدم ==========
    if (systolic != null && diastolic != null) {
      if (systolic >= 160 || diastolic >= 100) {
        riskScore += 20;
        riskFactors.add('ضغط دم حرج جداً (≥160/100)');
        recommendations.add('تشاور طبي فوري مطلوب');
      } else if (systolic >= 140 || diastolic >= 90) {
        riskScore += 12;
        riskFactors.add('ارتفاع ضغط دم (≥140/90)');
        recommendations.add('تجنب NSAIDs، راقب بانتظام');
      }
    }

    // ========== 🩸 تقييم السكر ==========
    if (bloodSugar != null) {
      if (bloodSugar >= 300) {
        riskScore += 18;
        riskFactors.add('سكر دم حرج جداً (≥300)');
        recommendations.add('تشاور فوري مع طبيب السكري');
      } else if (bloodSugar >= 200) {
        riskScore += 10;
        riskFactors.add('ارتفاع نسبة السكر (≥200)');
        recommendations.add('تجنب الستيرويدات، راقب بانتظام');
      } else if (bloodSugar < 70 && bloodSugar > 0) {
        riskScore += 15;
        riskFactors.add('انخفاض السكر (<70)');
        recommendations.add('تناول سكريات سريعة، اخفص جرعة الأنسولين');
      }
    }

    // ========== 📋 تقييم الأمراض المزمنة ==========
    if (chronicDiseases != null && chronicDiseases.isNotEmpty) {
      final chronic = chronicDiseases.toLowerCase();

      if (chronic.contains('kidney') ||
          chronic.contains('كلى') ||
          chronic.contains('renal')) {
        riskScore += 18;
        riskFactors.add('مرض كلوي مزمن');
        recommendations
            .add('اختبر الكرياتينين و GFR، قلل جرعات الأدوية الكلوية');
      }

      if (chronic.contains('liver') ||
          chronic.contains('كبد') ||
          chronic.contains('hepatic')) {
        riskScore += 18;
        riskFactors.add('مرض كبدي مزمن');
        recommendations.add('تجنب أدوية سامة للكبد، اختبر وظائف الكبد');
      }

      if (chronic.contains('heart') ||
          chronic.contains('قلب') ||
          chronic.contains('cardiac')) {
        riskScore += 15;
        riskFactors.add('مرض قلبي مزمن');
        recommendations.add('تجنب NSAIDs، راقب ضغط الدم');
      }

      if (chronic.contains('diabetes') || chronic.contains('سكري')) {
        riskScore += 12;
        riskFactors.add('داء السكري');
        recommendations.add('راقب السكر، تجنب الستيرويدات');
      }

      if (chronic.contains('asthma') || chronic.contains('ربو')) {
        riskScore += 10;
        riskFactors.add('الربو');
        recommendations.add('تجنب بيتا بلوكرز، اختر مسكنات آمنة');
      }
    }

    // ========== 💉 تقييم الحساسيات ==========
    if (allergies != null && allergies.isNotEmpty) {
      final allergyList = allergies.toLowerCase();

      if (allergyList.contains('penicillin')) {
        riskScore += 15;
        riskFactors.add('حساسية البنسلين');
        recommendations.add('تجنب البنسلين والسيفالوسبورينات، استخدم بدائل');
      }

      if (allergyList.contains('nsaid')) {
        riskScore += 12;
        riskFactors.add('حساسية NSAIDs');
        recommendations.add('استخدم باراسيتامول أو كوكسيبات بدلاً منها');
      }

      if (allergyList.contains('sulfa')) {
        riskScore += 10;
        riskFactors.add('حساسية السلفوناميد');
        recommendations.add('تجنب TMP-SMX والأدوية التي تحتوي على الكبريت');
      }
    }

    // ========== 💊 تقييم التفاعلات الدوائية ==========
    if (currentMedicines != null && currentMedicines.isNotEmpty) {
      // محاكاة فحص التفاعلات
      final interactionCount = _estimateInteractionCount(currentMedicines);
      riskScore += interactionCount * 8;
      if (interactionCount > 0) {
        riskFactors.add('${interactionCount} تفاعل محتمل بين الأدوية الحالية');
        recommendations.add('راجع قائمة الأدوية مع الصيدلي');
      }
    }

    // ========== 🎯 تحديد مستوى المخاطرة ==========
    String riskLevel;
    if (riskScore >= 80) {
      riskLevel = 'حرج جداً';
    } else if (riskScore >= 60) {
      riskLevel = 'مرتفع جداً';
    } else if (riskScore >= 40) {
      riskLevel = 'مرتفع';
    } else if (riskScore >= 20) {
      riskLevel = 'معتدل';
    } else {
      riskLevel = 'منخفض';
    }

    return PatientRiskAssessment(
      riskScore: riskScore.clamp(0, 100),
      riskLevel: riskLevel,
      riskFactors: riskFactors,
      recommendations: recommendations,
      requiresImmediateAttention: riskScore >= 60,
      estimatedReviewFrequency: _getReviewFrequency(riskScore),
    );
  }

  /// 🔍 تقدير عدد التفاعلات الدوائية
  int _estimateInteractionCount(List<String> medicines) {
    if (medicines.length < 2) return 0;
    // احسب عدد الأزواج المحتملة
    return (medicines.length * (medicines.length - 1)) ~/ 2;
  }

  /// 📅 الحصول على تكرار المراجعة الموصى به
  String _getReviewFrequency(int riskScore) {
    if (riskScore >= 80) {
      return 'يومي (خطر جداً)';
    } else if (riskScore >= 60) {
      return 'كل 3 أيام';
    } else if (riskScore >= 40) {
      return 'أسبوعي';
    } else if (riskScore >= 20) {
      return 'كل أسبوعين';
    } else {
      return 'شهري';
    }
  }
}

/// 📊 نتيجة تقييم مخاطر المريض
class PatientRiskAssessment {
  final int riskScore; // 0-100
  final String riskLevel;
  final List<String> riskFactors;
  final List<String> recommendations;
  final bool requiresImmediateAttention;
  final String estimatedReviewFrequency;

  PatientRiskAssessment({
    required this.riskScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.recommendations,
    required this.requiresImmediateAttention,
    required this.estimatedReviewFrequency,
  });

  /// 🎯 الحصول على لون التقييم
  String get riskColor {
    if (riskScore >= 80) return '🔴'; // حرج
    if (riskScore >= 60) return '🟠'; // مرتفع جداً
    if (riskScore >= 40) return '🟡'; // مرتفع
    if (riskScore >= 20) return '🟡'; // معتدل
    return '🟢'; // منخفض
  }

  /// 📋 الملخص النصي للتقييم
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('$riskColor تقييم المخاطر: $riskLevel ($riskScore/100)');
    buffer.writeln('\n📋 عوامل الخطر:');
    for (final factor in riskFactors) {
      buffer.writeln('• $factor');
    }
    buffer.writeln('\n💡 التوصيات:');
    for (final rec in recommendations) {
      buffer.writeln('• $rec');
    }
    buffer.writeln('\n📅 تكرار المراجعة: $estimatedReviewFrequency');
    return buffer.toString();
  }

  /// 🚨 هل يتطلب انتباهاً فورياً؟
  bool get needsUrgentReview => requiresImmediateAttention;
}

/// 🏥 فئات مستويات المخاطرة
class RiskLevel {
  static const String low = 'منخفض';
  static const String moderate = 'معتدل';
  static const String high = 'مرتفع';
  static const String veryHigh = 'مرتفع جداً';
  static const String critical = 'حرج جداً';

  static String getEmoji(String level) {
    switch (level) {
      case critical:
        return '🔴';
      case veryHigh:
        return '🟠';
      case high:
        return '🟡';
      case moderate:
        return '🟡';
      case low:
      default:
        return '🟢';
    }
  }
}
