import '../utils/pediatric_dosage_data.dart';
import '../../features/prescription/domain/medical_entity_resolver.dart';

class DosageCalculationResult {
  final double calculatedDoseMg;
  final double calculatedDoseMl;
  final String frequency;
  final String message;
  final bool isSafe;

  DosageCalculationResult({
    required this.calculatedDoseMg,
    required this.calculatedDoseMl,
    required this.frequency,
    required this.message,
    this.isSafe = true,
  });
}

/// 🧠 حاسبة الجرعات السريرية (Clinical Dosage Calculator)
/// تقوم بحساب الجرعات الدقيقة للأطفال والكبار بناءً على الوزن والعمر
class ClinicalDosageCalculator {
  
  /// حساب الجرعة السائلة للأطفال بناءً على الوزن
  static DosageCalculationResult? calculatePediatricDose(String medicineName, double weightKg) {
    if (weightKg <= 0) return null;

    final genericName = MedicalEntityResolver.resolve(medicineName);
    final rule = PediatricDosageData.rules[genericName.toLowerCase()];

    if (rule == null) {
      return null; // لا توجد قاعدة بروتوكولية لهذا الدواء
    }

    double doseMg = 0.0;
    
    if (rule.dosePerKgPerDose != null) {
      // أدوية تحسب لكل جرعة (مثل الباراسيتامول)
      doseMg = rule.dosePerKgPerDose! * weightKg;
    } else if (rule.dosePerKgPerDay != null) {
      // أدوية تحسب لكل يوم وتقسم (مثل المضادات الحيوية)
      double totalDailyDoseMg = rule.dosePerKgPerDay! * weightKg;
      if (totalDailyDoseMg > rule.maxDosePerDay) {
        totalDailyDoseMg = rule.maxDosePerDay; // الحد الأقصى الآمن
      }
      doseMg = totalDailyDoseMg / rule.dividedIntoDoses;
    }

    // حساب كمية السائل بالملليلتر (mL)
    // Formula: (Dose_mg / Standard_Mg) * Standard_Ml
    double doseMl = (doseMg / rule.standardConcentrationMg) * rule.standardConcentrationMl;

    // تقريب إلى أقرب نصف مل (مثال: 4.2 -> 4.0, 4.8 -> 5.0, 4.4 -> 4.5)
    doseMl = (doseMl * 2).roundToDouble() / 2.0;

    return DosageCalculationResult(
      calculatedDoseMg: doseMg.roundToDouble(),
      calculatedDoseMl: doseMl,
      frequency: rule.frequency,
      message: 'الجرعة المحسوبة للوزن ($weightKg كجم): $doseMl مل (${doseMg.toInt()} ملغ) ${rule.frequency}.\n${rule.notes}',
      isSafe: true,
    );
  }

  /// دالة ذكية تستخدم داخل المحلل الصوتي أو الإدخال اليدوي
  static String autoFormatPediatricPrescription(String medicineName, double weightKg) {
    final result = calculatePediatricDose(medicineName, weightKg);
    if (result == null) return medicineName; // إذا لم يكن طفلاً أو لم نجد قاعدة

    return '$medicineName ${result.calculatedDoseMl} مل (${result.calculatedDoseMg.toInt()}mg) ${result.frequency}';
  }
}
