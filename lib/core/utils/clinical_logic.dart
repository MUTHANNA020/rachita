import 'package:flutter/material.dart';

enum BPStatus { normal, elevated, stage1, stage2, crisis, unknown }

enum BMIStatus { underweight, normal, overweight, obese, unknown }

enum TempStatus { hypothermia, normal, fever, unknown }

class ClinicalSpecialty {
  final String id;
  final String nameAr;
  final String nameEn;
  final List<String> requiredVitals;
  final IconData icon;

  const ClinicalSpecialty({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.requiredVitals,
    this.icon = Icons.medical_services_outlined,
  });
}

class ClinicalLogic {
  static const List<ClinicalSpecialty> specialties = [
    ClinicalSpecialty(
      id: 'gp',
      nameAr: 'ممارسة عامة',
      nameEn: 'General Practice',
      requiredVitals: ['weight', 'systolic', 'diastolic', 'pulse', 'sugar', 'temperature'],
      icon: Icons.health_and_safety_outlined,
    ),
    ClinicalSpecialty(
      id: 'peds',
      nameAr: 'طب الأطفال',
      nameEn: 'Pediatrics',
      requiredVitals: ['weight', 'height', 'head_circ', 'temperature', 'pulse'],
      icon: Icons.child_care_rounded,
    ),
    ClinicalSpecialty(
      id: 'cardio',
      nameAr: 'طب القلب',
      nameEn: 'Cardiology',
      requiredVitals: ['weight', 'systolic', 'diastolic', 'pulse', 'sugar'],
      icon: Icons.monitor_heart_outlined,
    ),
    ClinicalSpecialty(
      id: 'dentist',
      nameAr: 'طبيب أسنان',
      nameEn: 'Dentistry',
      requiredVitals: ['systolic', 'diastolic', 'pulse', 'temperature'],
      icon: Icons.personal_video_rounded,
    ),
    ClinicalSpecialty(
      id: 'obgyn',
      nameAr: 'طب النساء والتوليد',
      nameEn: 'Obstetrics & Gynecology',
      requiredVitals: ['weight', 'systolic', 'diastolic', 'pulse', 'sugar'],
      icon: Icons.pregnant_woman_rounded,
    ),
    ClinicalSpecialty(
      id: 'derma',
      nameAr: 'طب الجلدية',
      nameEn: 'Dermatology',
      requiredVitals: ['weight', 'temperature'],
      icon: Icons.face_retouching_natural_rounded,
    ),
    ClinicalSpecialty(
      id: 'ortho',
      nameAr: 'طب العظام',
      nameEn: 'Orthopedics',
      requiredVitals: ['weight', 'pulse'],
      icon: Icons.accessibility_new_rounded,
    ),
    ClinicalSpecialty(
      id: 'neuro',
      nameAr: 'طب الأعصاب',
      nameEn: 'Neurology',
      requiredVitals: ['systolic', 'diastolic', 'pulse', 'temperature'],
      icon: Icons.psychology_outlined,
    ),
    ClinicalSpecialty(
      id: 'psych',
      nameAr: 'الطب النفسي',
      nameEn: 'Psychiatry',
      requiredVitals: ['weight', 'pulse'],
      icon: Icons.self_improvement_rounded,
    ),
    ClinicalSpecialty(
      id: 'internal',
      nameAr: 'الطب الباطني',
      nameEn: 'Internal Medicine',
      requiredVitals: ['weight', 'systolic', 'diastolic', 'pulse', 'sugar', 'temperature'],
      icon: Icons.medication_liquid_sharp,
    ),
    ClinicalSpecialty(
      id: 'ent',
      nameAr: 'الأنف والأذن والحنجرة',
      nameEn: 'ENT',
      requiredVitals: ['temperature', 'pulse'],
      icon: Icons.hearing_rounded,
    ),
    ClinicalSpecialty(
      id: 'ophth',
      nameAr: 'طب العيون',
      nameEn: 'Ophthalmology',
      requiredVitals: ['systolic', 'diastolic', 'sugar'],
      icon: Icons.visibility_rounded,
    ),
    ClinicalSpecialty(
      id: 'uro',
      nameAr: 'طب المسالك البولية',
      nameEn: 'Urology',
      requiredVitals: ['weight', 'systolic', 'diastolic', 'sugar'],
      icon: Icons.water_drop_outlined,
    ),
  ];

  static List<String> getRequiredVitals(String specialtyName) {
    final specialty = specialties.firstWhere(
      (s) => s.nameAr == specialtyName || s.nameEn == specialtyName || s.id == specialtyName,
      orElse: () => specialties.first, // Default to GP
    );
    return specialty.requiredVitals;
  }

  static BMIStatus calculateBMIStatus(double? weight, double? heightCm) {
    if (weight == null || heightCm == null || heightCm == 0) return BMIStatus.unknown;
    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);
    if (bmi < 18.5) return BMIStatus.underweight;
    if (bmi < 25) return BMIStatus.normal;
    if (bmi < 30) return BMIStatus.overweight;
    return BMIStatus.obese;
  }

  static double? calculateBMI(double? weight, double? heightCm) {
    if (weight == null || heightCm == null || heightCm == 0) return null;
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  static BPStatus interpretBP(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return BPStatus.unknown;
    
    if (systolic > 180 || diastolic > 120) return BPStatus.crisis;
    if (systolic >= 140 || diastolic >= 90) return BPStatus.stage2;
    if (systolic >= 130 || diastolic >= 80) return BPStatus.stage1;
    if (systolic >= 120 && diastolic < 80) return BPStatus.elevated;
    if (systolic < 120 && diastolic < 80) return BPStatus.normal;
    
    return BPStatus.unknown;
  }

  static TempStatus interpretTemp(double? temp) {
    if (temp == null) return TempStatus.unknown;
    if (temp < 35.0) return TempStatus.hypothermia;
    if (temp > 38.0) return TempStatus.fever;
    return TempStatus.normal;
  }

  static String getBMIAr(BMIStatus status) {
    switch (status) {
      case BMIStatus.underweight: return 'نقص وزن';
      case BMIStatus.normal: return 'وزن مثالي';
      case BMIStatus.overweight: return 'وزن زائد';
      case BMIStatus.obese: return 'سمنة';
      default: return '--';
    }
  }

  static String getBPStatusAr(BPStatus status) {
    switch (status) {
      case BPStatus.normal: return 'طبيعي';
      case BPStatus.elevated: return 'مرتفع قليلاً';
      case BPStatus.stage1: return 'ضغط مرتفع (1)';
      case BPStatus.stage2: return 'ضغط مرتفع (2)';
      case BPStatus.crisis: return 'أزمة ضغط حادة ⚠️';
      default: return '--';
    }
  }

  static Color getBPColor(BPStatus status) {
    switch (status) {
      case BPStatus.normal: return Colors.green;
      case BPStatus.elevated: return Colors.orange;
      case BPStatus.stage1: return Colors.deepOrange;
      case BPStatus.stage2: return Colors.red;
      case BPStatus.crisis: return Colors.purple;
      default: return Colors.grey;
    }
  }


  static String? checkMedicineSafety(String medName, String? category, String allergies) {
    if (allergies.isEmpty) return null;
    final lowerMed = medName.toLowerCase();
    final lowerCat = category?.toLowerCase() ?? '';
    final lowerAllergies = allergies.toLowerCase();

    // Simple heuristic matching
    if (lowerAllergies.contains(lowerMed)) return 'المريض لديه حساسية من هذا الدواء: $medName';
    if (lowerCat.isNotEmpty && lowerAllergies.contains(lowerCat)) return 'المريض لديه حساسية من عائلة هذا الدواء: $category';
    
    return null;
  }

  static List<String> detectDuplicateClass(List<String> categories) {
    final seen = <String>{};
    final duplicates = <String>[];
    for (final cat in categories) {
      if (cat.isEmpty) continue;
      if (seen.contains(cat)) {
        duplicates.add(cat);
      }
      seen.add(cat);
    }
    return duplicates;
  }

  static int calculateVitalsRisk(int? systolic, int? diastolic, double? temp, int? pulse) {
    int score = 0;
    
    // BP Risk
    final bp = interpretBP(systolic, diastolic);
    if (bp == BPStatus.crisis) score += 5;
    if (bp == BPStatus.stage2) score += 3;

    // Temp Risk
    final t = interpretTemp(temp);
    if (t == TempStatus.fever) score += 2;
    if (t == TempStatus.hypothermia) score += 3;

    // Pulse Risk
    if (pulse != null) {
      if (pulse > 120 || pulse < 50) score += 3;
    }

    return score;
  }
}
