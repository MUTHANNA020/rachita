import 'package:flutter_test/flutter_test.dart';
import 'package:rachita/features/prescription/domain/services/risk_assessment_service.dart';

void main() {
  late RiskAssessmentService service;

  setUp(() {
    service = RiskAssessmentService();
  });

  group('RiskAssessmentService - Age Risk', () {
    test('طفل أقل من 5 سنوات = مخاطر مرتفعة', () {
      final result = service.assessPatientRisk(
        age: 3, ageCategory: 0, isPregnant: false,
        chronicDiseases: null, allergies: null,
        systolic: null, diastolic: null, bloodSugar: null,
        currentMedicines: null,
      );
      expect(result.riskScore, greaterThanOrEqualTo(15));
      expect(result.riskFactors, isNotEmpty);
    });

    test('مريض أكبر من 75 سنة = مخاطر مرتفعة جداً', () {
      final result = service.assessPatientRisk(
        age: 80, ageCategory: 4, isPregnant: false,
        chronicDiseases: null, allergies: null,
        systolic: null, diastolic: null, bloodSugar: null,
        currentMedicines: null,
      );
      expect(result.riskScore, greaterThanOrEqualTo(25));
    });

    test('بالغ طبيعي = مخاطر منخفضة', () {
      final result = service.assessPatientRisk(
        age: 35, ageCategory: 2, isPregnant: false,
        chronicDiseases: null, allergies: null,
        systolic: null, diastolic: null, bloodSugar: null,
        currentMedicines: null,
      );
      expect(result.riskScore, lessThan(20));
    });
  });

  group('RiskAssessmentService - Pregnancy Risk', () {
    test('حالة الحمل تُضيف 30 نقطة خطر', () {
      final withPregnancy = service.assessPatientRisk(
        age: 28, ageCategory: 2, isPregnant: true,
        chronicDiseases: null, allergies: null,
        systolic: null, diastolic: null, bloodSugar: null,
        currentMedicines: null,
      );
      final withoutPregnancy = service.assessPatientRisk(
        age: 28, ageCategory: 2, isPregnant: false,
        chronicDiseases: null, allergies: null,
        systolic: null, diastolic: null, bloodSugar: null,
        currentMedicines: null,
      );
      expect(withPregnancy.riskScore - withoutPregnancy.riskScore, greaterThanOrEqualTo(25));
    });
  });

  group('RiskAssessmentService - Vitals Risk', () {
    test('ضغط دم حرج (>= 160/100) = مخاطر عالية', () {
      final result = service.assessPatientRisk(
        age: 50, ageCategory: 2, isPregnant: false,
        chronicDiseases: null, allergies: null,
        systolic: 170.0, diastolic: 105.0, bloodSugar: null,
        currentMedicines: null,
      );
      expect(result.riskScore, greaterThanOrEqualTo(20));
      expect(result.riskFactors.any((f) => f.contains('ضغط')), isTrue);
    });

    test('سكر دم حرج (>= 300) = مخاطر عالية', () {
      final result = service.assessPatientRisk(
        age: 50, ageCategory: 2, isPregnant: false,
        chronicDiseases: 'سكري', allergies: null,
        systolic: null, diastolic: null, bloodSugar: 320.0,
        currentMedicines: null,
      );
      expect(result.riskScore, greaterThanOrEqualTo(30));
      expect(result.riskFactors.any((f) => f.contains('سكر')), isTrue);
    });

    test('انخفاض السكر (< 70) = مخاطر مرتفعة', () {
      final result = service.assessPatientRisk(
        age: 50, ageCategory: 2, isPregnant: false,
        chronicDiseases: null, allergies: null,
        systolic: null, diastolic: null, bloodSugar: 55.0,
        currentMedicines: null,
      );
      expect(result.riskFactors.any((f) => f.contains('انخفاض')), isTrue);
    });
  });

  group('RiskAssessmentService - Chronic Disease Risk', () {
    test('مرض الكلى يرفع درجة الخطر', () {
      final result = service.assessPatientRisk(
        age: 55, ageCategory: 2, isPregnant: false,
        chronicDiseases: 'Chronic Kidney Disease', allergies: null,
        systolic: null, diastolic: null, bloodSugar: null,
        currentMedicines: null,
      );
      expect(result.riskScore, greaterThanOrEqualTo(18));
      expect(result.riskFactors.any((f) => f.contains('كلوي')), isTrue);
    });

    test('الربو يُنبه لتجنب البيتا بلوكر', () {
      final result = service.assessPatientRisk(
        age: 40, ageCategory: 2, isPregnant: false,
        chronicDiseases: 'asthma', allergies: null,
        systolic: null, diastolic: null, bloodSugar: null,
        currentMedicines: null,
      );
      expect(result.recommendations.any((r) => r.contains('بيتا')), isTrue);
    });
  });

  group('RiskAssessmentService - Risk Level', () {
    test('riskScore في النطاق 0-100', () {
      final result = service.assessPatientRisk(
        age: 3, ageCategory: 0, isPregnant: true,
        chronicDiseases: 'kidney disease, liver disease, heart disease',
        allergies: 'penicillin, nsaid',
        systolic: 170.0, diastolic: 110.0, bloodSugar: 350.0,
        currentMedicines: ['warfarin', 'aspirin', 'ibuprofen'],
      );
      expect(result.riskScore, inInclusiveRange(0, 100));
    });

    test('requiresImmediateAttention عند 60+', () {
      final result = service.assessPatientRisk(
        age: 80, ageCategory: 4, isPregnant: false,
        chronicDiseases: 'kidney disease, heart disease',
        allergies: null,
        systolic: 175.0, diastolic: 105.0, bloodSugar: 310.0,
        currentMedicines: null,
      );
      expect(result.requiresImmediateAttention, isTrue);
    });
  });
}
