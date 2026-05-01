import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rachita/features/prescription/domain/services/drug_interaction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  SharedPreferences.setMockInitialValues({});

  late DrugInteractionService service;

  setUp(() {
    service = DrugInteractionService();
  });

  group('DrugInteractionService - checkInteraction', () {
    test('يكتشف تفاعل Warfarin + Aspirin (Critical)', () async {
      final result = await service.checkInteraction('warfarin', 'aspirin');
      expect(result.hasInteraction, isTrue);
      expect(result.severity, InteractionSeverity.critical);
      expect(result.isCritical, isTrue);
    });

    test('يكتشف تفاعل Warfarin + Ibuprofen (Critical)', () async {
      final result = await service.checkInteraction('warfarin', 'ibuprofen');
      expect(result.hasInteraction, isTrue);
      expect(result.severity, InteractionSeverity.critical);
    });

    test('يكتشف تفاعل Aspirin + Ibuprofen (Moderate)', () async {
      final result = await service.checkInteraction('aspirin', 'ibuprofen');
      expect(result.hasInteraction, isTrue);
      expect(result.severity, isNot(InteractionSeverity.none));
    });

    test('يكتشف تفاعل Metformin + Contrast Dye (Critical)', () async {
      final result = await service.checkInteraction('metformin', 'contrast_dye');
      expect(result.hasInteraction, isTrue);
      expect(result.severity, InteractionSeverity.critical);
    });

    test('يعيد لا تفاعل بين Paracetamol و Amoxicillin', () async {
      final result = await service.checkInteraction('paracetamol', 'amoxicillin');
      expect(result.hasInteraction, isFalse);
      expect(result.severity, InteractionSeverity.none);
    });

    test('يعمل في الاتجاهين (A-B = B-A)', () async {
      final ab = await service.checkInteraction('warfarin', 'ibuprofen');
      final ba = await service.checkInteraction('ibuprofen', 'warfarin');
      expect(ab.hasInteraction, ba.hasInteraction);
      expect(ab.severity, ba.severity);
    });

    test('يتعامل مع الأسماء التجارية تلقائياً', () async {
      // Coumadin هو الاسم التجاري لـ Warfarin
      final result = await service.checkInteraction('Coumadin', 'Brufen');
      expect(result.hasInteraction, isTrue);
    });
  });

  group('DrugInteractionService - checkMultipleInteractions', () {
    test('يفحص قائمة أدوية ويكتشف كل التفاعلات', () async {
      final results = await service.checkMultipleInteractions([
        'warfarin', 'aspirin', 'paracetamol',
      ]);
      expect(results, isNotEmpty);
      expect(results.any((r) => r.isCritical), isTrue);
    });

    test('يرتب التفاعلات بالحدة (Critical أولاً)', () async {
      final results = await service.checkMultipleInteractions([
        'warfarin', 'aspirin', 'ibuprofen', 'paracetamol',
      ]);
      if (results.length > 1) {
        for (int i = 0; i < results.length - 1; i++) {
          expect(results[i].severity.index, greaterThanOrEqualTo(results[i + 1].severity.index));
        }
      }
    });

    test('يُعيد قائمة فارغة لأدوية آمنة', () async {
      final results = await service.checkMultipleInteractions([
        'paracetamol', 'omeprazole',
      ]);
      expect(results, isEmpty);
    });
  });

  group('DrugInteractionService - getStatistics', () {
    test('يحسب الإحصائيات بدقة', () async {
      final stats = await service.getStatistics(['warfarin', 'aspirin', 'ibuprofen', 'paracetamol']);
      expect(stats.totalInteractions, greaterThan(0));
      expect(stats.criticalCount, greaterThan(0));
    });

    test('hasCriticalInteractions يُعيد true عند وجود حرج', () async {
      final stats = await service.getStatistics(['warfarin', 'aspirin']);
      expect(stats.hasCriticalInteractions, isTrue);
    });

    test('riskPercentage في النطاق الصحيح', () async {
      final stats = await service.getStatistics(['warfarin', 'aspirin']);
      expect(stats.riskPercentage, inInclusiveRange(0, 100));
    });
  });

  group('DrugInteractionService - clinicalMessage', () {
    test('يوفر رسالة سريرية مناسبة', () async {
      final result = await service.checkInteraction('warfarin', 'aspirin');
      expect(result.clinicalMessage, contains('🚨'));
      expect(result.clinicalMessage, isNotEmpty);
    });

    test('رسالة آمنة عند لا توجد تفاعلات', () async {
      final result = await service.checkInteraction('paracetamol', 'omeprazole');
      expect(result.clinicalMessage, contains('لا توجد'));
    });
  });
}
