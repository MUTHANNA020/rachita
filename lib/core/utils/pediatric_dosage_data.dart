/// 📚 قاعدة بيانات مرجعية لجرعات الأطفال (Pediatric Dosage Reference)
/// تستند إلى البروتوكولات الطبية المعتمدة لحساب الجرعات (mg/kg/day).
class PediatricDosageData {
  static const Map<String, PediatricDrugRules> rules = {
    'paracetamol': PediatricDrugRules(
      genericName: 'Paracetamol',
      dosePerKgPerDose: 15.0, // 10-15 mg/kg/dose
      maxDosePerDay: 4000.0,
      standardConcentrationMg: 120.0, // 120mg/5mL or 250mg/5mL
      standardConcentrationMl: 5.0,
      frequency: 'كل 6-8 ساعات',
      notes: 'لا تتجاوز 4 جرعات في 24 ساعة',
    ),
    'ibuprofen': PediatricDrugRules(
      genericName: 'Ibuprofen',
      dosePerKgPerDose: 10.0, // 5-10 mg/kg/dose
      maxDosePerDay: 2400.0,
      standardConcentrationMg: 100.0, // 100mg/5mL
      standardConcentrationMl: 5.0,
      frequency: 'كل 6-8 ساعات',
      notes: 'يفضل بعد الطعام، غير مستحب للأقل من 6 أشهر',
    ),
    'amoxicillin': PediatricDrugRules(
      genericName: 'Amoxicillin',
      dosePerKgPerDay: 90.0, // 80-90 mg/kg/day for Otitis Media / severe
      dividedIntoDoses: 2,   // BID
      maxDosePerDay: 3000.0,
      standardConcentrationMg: 250.0, // 250mg/5mL
      standardConcentrationMl: 5.0,
      frequency: 'مرتين يومياً',
      notes: 'يعطى بجرعة مقسمة مرتين أو 3 مرات يومياً حسب شدة العدوى',
    ),
    'amoxicillin_clavulanate': PediatricDrugRules(
      genericName: 'Amoxicillin/Clavulanate',
      dosePerKgPerDay: 90.0, // Based on Amoxicillin component
      dividedIntoDoses: 2,
      maxDosePerDay: 4000.0,
      standardConcentrationMg: 228.0, // e.g. 228mg/5mL or 457mg/5mL
      standardConcentrationMl: 5.0,
      frequency: 'مرتين يومياً',
      notes: 'جرعة محسوبة بناءً على مكون الأموكسيسيلين (Augmentin)',
    ),
    'azithromycin': PediatricDrugRules(
      genericName: 'Azithromycin',
      dosePerKgPerDay: 10.0, // 10mg/kg day 1, then 5mg/kg days 2-5 OR 10mg/kg for 3 days
      dividedIntoDoses: 1,
      maxDosePerDay: 500.0,
      standardConcentrationMg: 200.0, // 200mg/5mL
      standardConcentrationMl: 5.0,
      frequency: 'مرة يومياً',
      notes: 'لمدة 3 أيام متتالية كجرعة قياسية',
    ),
    'cefixime': PediatricDrugRules(
      genericName: 'Cefixime',
      dosePerKgPerDay: 8.0, // 8 mg/kg/day
      dividedIntoDoses: 1,  // Can be divided into 2 doses (4mg/kg BID)
      maxDosePerDay: 400.0,
      standardConcentrationMg: 100.0, // 100mg/5mL
      standardConcentrationMl: 5.0,
      frequency: 'مرة يومياً',
      notes: 'يمكن تقسيمه لمرتين يومياً',
    ),
  };
}

class PediatricDrugRules {
  final String genericName;
  final double? dosePerKgPerDose; // For drugs dosed PRN like antipyretics
  final double? dosePerKgPerDay;  // For antibiotics dosed per day divided
  final int dividedIntoDoses;     // Usually 1, 2, 3, or 4
  final double maxDosePerDay;
  final double standardConcentrationMg; // Concentration (e.g. 120mg in 5ml)
  final double standardConcentrationMl;
  final String frequency;
  final String notes;

  const PediatricDrugRules({
    required this.genericName,
    this.dosePerKgPerDose,
    this.dosePerKgPerDay,
    this.dividedIntoDoses = 1,
    required this.maxDosePerDay,
    required this.standardConcentrationMg,
    required this.standardConcentrationMl,
    required this.frequency,
    required this.notes,
  });
}
