import 'package:flutter_test/flutter_test.dart';
import 'package:rachita/features/prescription/domain/medical_entity_resolver.dart';

void main() {
  group('MedicalEntityResolver - Brand to Generic Tests', () {
    test('يترجم Panadol إلى paracetamol', () {
      expect(MedicalEntityResolver.resolve('Panadol'), 'paracetamol');
      expect(MedicalEntityResolver.resolve('panadol'), 'paracetamol');
      expect(MedicalEntityResolver.resolve('بندول'), 'paracetamol');
    });

    test('يترجم Brufen إلى ibuprofen', () {
      expect(MedicalEntityResolver.resolve('Brufen'), 'ibuprofen');
      expect(MedicalEntityResolver.resolve('Advil'), 'ibuprofen');
      expect(MedicalEntityResolver.resolve('بروفين'), 'ibuprofen');
    });

    test('يترجم Augmentin إلى amoxicillin_clavulanate', () {
      expect(MedicalEntityResolver.resolve('Augmentin'), 'amoxicillin_clavulanate');
      expect(MedicalEntityResolver.resolve('أوجمنتين'), 'amoxicillin_clavulanate');
    });

    test('يترجم Voltaren إلى diclofenac', () {
      expect(MedicalEntityResolver.resolve('Voltaren'), 'diclofenac');
      expect(MedicalEntityResolver.resolve('فولتارين'), 'diclofenac');
    });

    test('يترجم Glucophage إلى metformin', () {
      expect(MedicalEntityResolver.resolve('Glucophage'), 'metformin');
      expect(MedicalEntityResolver.resolve('ميتفورمين'), 'metformin');
    });

    test('يُعيد الاسم كما هو إذا لم يجد ترجمة', () {
      expect(MedicalEntityResolver.resolve('unknowndrug'), 'unknowndrug');
    });
  });

  group('MedicalEntityResolver - Pregnancy Safety Tests', () {
    test('يحظر Warfarin في الحمل', () {
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('warfarin'), isTrue);
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('Coumadin'), isTrue);
    });

    test('يحظر Methotrexate في الحمل', () {
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('methotrexate'), isTrue);
    });

    test('يحظر Ibuprofen في الحمل', () {
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('ibuprofen'), isTrue);
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('Brufen'), isTrue);
    });

    test('يحظر Isotretinoin (Roaccutane) في الحمل', () {
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('Roaccutane'), isTrue);
    });

    test('لا يحظر Paracetamol في الحمل', () {
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('paracetamol'), isFalse);
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('Panadol'), isFalse);
    });

    test('لا يحظر Amoxicillin في الحمل', () {
      expect(MedicalEntityResolver.isContraindicatedInPregnancy('amoxicillin'), isFalse);
    });
  });

  group('MedicalEntityResolver - Drug Interaction Tests', () {
    test('يكتشف تفاعل Warfarin + Aspirin', () {
      final result = MedicalEntityResolver.checkInteraction('warfarin', 'aspirin');
      expect(result, isNotNull);
      expect(result!['severity'], 'Critical');
    });

    test('يكتشف تفاعل Aspirin + Warfarin (الاتجاه المعكوس)', () {
      final result = MedicalEntityResolver.checkInteraction('aspirin', 'warfarin');
      expect(result, isNotNull);
    });

    test('يكتشف تفاعل Warfarin + Ibuprofen', () {
      final result = MedicalEntityResolver.checkInteraction('Coumadin', 'Brufen');
      expect(result, isNotNull);
      expect(result!['severity'], 'Critical');
    });

    test('لا يجد تفاعل بين Panadol و Amoxil', () {
      final result = MedicalEntityResolver.checkInteraction('Panadol', 'Amoxil');
      expect(result, isNull);
    });

    test('يكتشف تفاعل Warfarin + Metronidazole', () {
      final result = MedicalEntityResolver.checkInteraction('warfarin', 'flagyl');
      expect(result, isNotNull);
    });
  });

  group('MedicalEntityResolver - Allergy Conflict Tests', () {
    test('يكتشف حساسية البنسلين مع Amoxicillin', () {
      final alerts = MedicalEntityResolver.checkAllergyConflicts(
        'penicillin allergy',
        ['Amoxil', 'Panadol'],
      );
      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.contains('Amoxil')), isTrue);
    });

    test('يكتشف حساسية البنسلين مع Augmentin', () {
      final alerts = MedicalEntityResolver.checkAllergyConflicts(
        'بنسلين',
        ['Augmentin'],
      );
      expect(alerts, isNotEmpty);
    });

    test('لا ينبه إذا لا يوجد تعارض حساسية', () {
      final alerts = MedicalEntityResolver.checkAllergyConflicts(
        'penicillin',
        ['Panadol', 'Nexium'],
      );
      expect(alerts, isEmpty);
    });

    test('يكتشف حساسية NSAIDs', () {
      final alerts = MedicalEntityResolver.checkAllergyConflicts(
        'nsaid allergy',
        ['Brufen', 'Panadol'],
      );
      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.contains('Brufen')), isTrue);
    });
  });

  group('MedicalEntityResolver - checkAllInteractions Tests', () {
    test('يفحص قائمة كاملة ويرتبها حسب الحدة', () {
      final warnings = MedicalEntityResolver.checkAllInteractions([
        'warfarin', 'aspirin', 'paracetamol', 'ibuprofen',
      ]);
      expect(warnings, isNotEmpty);
      // التحقق أن Critical يأتي أولاً
      if (warnings.length > 1) {
        const order = {'Critical': 0, 'High': 1, 'Moderate': 2, 'Low': 3};
        for (int i = 0; i < warnings.length - 1; i++) {
          final a = order[warnings[i].severity] ?? 4;
          final b = order[warnings[i + 1].severity] ?? 4;
          expect(a, lessThanOrEqualTo(b));
        }
      }
    });

    test('يُعيد قائمة فارغة لأدوية آمنة', () {
      final warnings = MedicalEntityResolver.checkAllInteractions([
        'paracetamol', 'omeprazole', 'azithromycin',
      ]);
      expect(warnings, isEmpty);
    });
  });
}
