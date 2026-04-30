import 'package:rachita/features/prescription/domain/medical_entity_resolver.dart';
import 'package:rachita/core/database/database_helper.dart';
import 'package:rachita/core/database/database_constants.dart';

/// 🏥 خدمة فحص تفاعلات الأدوية المتقدمة (Real Medical Brain)
/// تعتمد على قاعدة بيانات محلية (SQLite) بدلاً من الشروط الثابتة لضمان الدقة وتغطية أوسع.
class DrugInteractionService {
  static final DrugInteractionService _instance =
      DrugInteractionService._internal();

  factory DrugInteractionService() {
    return _instance;
  }

  DrugInteractionService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 🔍 فحص التفاعلات بين دواءين (مع الترجمة التلقائية للاسم التجاري)
  Future<DrugInteractionResult> checkInteraction(String drug1, String drug2) async {
    // 🧠 الخطوة الذكية: ترجمة الاسم التجاري → العلمي قبل البحث
    final g1 = MedicalEntityResolver.resolve(drug1)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final g2 = MedicalEntityResolver.resolve(drug2)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // استعلام قاعدة البيانات الحقيقية
    final db = await _dbHelper.database;
    final results = await db.query(
      DBConstants.tableDrugInteractions,
      where: '(drug1 = ? AND drug2 = ?) OR (drug1 = ? AND drug2 = ?)',
      whereArgs: [g1, g2, g2, g1],
    );

    if (results.isNotEmpty) {
      final entry = results.first;
      return DrugInteractionResult(
        hasInteraction: true,
        severity: _parseSeverityInt(entry['severity'] as int?),
        description: entry['interaction_description'] as String?,
        recommendation: entry['recommendation'] as String?,
        mechanism: entry['evidence_source'] as String?,
        drug1: drug1,
        drug2: drug2,
      );
    }

    // إذا لم نجد في DB الجديدة، نجرب المترجم الشامل كإجراء احتياطي (Fallback)
    final resolverResult = MedicalEntityResolver.checkInteraction(drug1, drug2);
    if (resolverResult != null) {
      return DrugInteractionResult(
        hasInteraction: true,
        severity: _parseSeverityString(resolverResult['severity'] ?? 'Moderate'),
        description: resolverResult['description'],
        recommendation: resolverResult['recommendation'],
        mechanism: null,
        drug1: drug1,
        drug2: drug2,
      );
    }

    return DrugInteractionResult(
      hasInteraction: false,
      severity: InteractionSeverity.none,
      drug1: drug1,
      drug2: drug2,
    );
  }

  InteractionSeverity _parseSeverityInt(int? severity) {
    if (severity == null) return InteractionSeverity.moderate;
    switch (severity) {
      case 4: return InteractionSeverity.critical;
      case 3: return InteractionSeverity.high;
      case 2: return InteractionSeverity.moderate;
      case 1: return InteractionSeverity.low;
      case 0: return InteractionSeverity.none;
      default: return InteractionSeverity.moderate;
    }
  }

  InteractionSeverity _parseSeverityString(String s) {
    switch (s.toLowerCase()) {
      case 'critical': return InteractionSeverity.critical;
      case 'high':     return InteractionSeverity.high;
      case 'moderate': return InteractionSeverity.moderate;
      case 'low':      return InteractionSeverity.low;
      default:         return InteractionSeverity.moderate;
    }
  }

  /// 📋 فحص قائمة الأدوية للتفاعلات المتعددة بشكل ديناميكي
  Future<List<DrugInteractionResult>> checkMultipleInteractions(
      List<String> medicines) async {
    final results = <DrugInteractionResult>[];

    for (int i = 0; i < medicines.length; i++) {
      for (int j = i + 1; j < medicines.length; j++) {
        final result = await checkInteraction(medicines[i], medicines[j]);
        if (result.hasInteraction) {
          results.add(result);
        }
      }
    }

    // ترتيب النتائج حسب الحدة
    results.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return results;
  }

  /// 🚨 الحصول على أخطر تفاعل
  Future<DrugInteractionResult?> getCriticalInteraction(List<String> medicines) async {
    final interactions = await checkMultipleInteractions(medicines);
    if (interactions.isEmpty) return null;

    for (final result in interactions) {
      if (result.severity == InteractionSeverity.critical) {
        return result;
      }
    }
    return null;
  }

  /// 📊 إحصائيات التفاعلات
  Future<InteractionStatistics> getStatistics(List<String> medicines) async {
    final interactions = await checkMultipleInteractions(medicines);
    return InteractionStatistics(
      totalInteractions: interactions.length,
      criticalCount: interactions
          .where((i) => i.severity == InteractionSeverity.critical)
          .length,
      highCount: interactions
          .where((i) => i.severity == InteractionSeverity.high)
          .length,
      moderateCount: interactions
          .where((i) => i.severity == InteractionSeverity.moderate)
          .length,
      lowCount: interactions
          .where((i) => i.severity == InteractionSeverity.low)
          .length,
      interactions: interactions,
    );
  }
}

/// 📊 نتيجة فحص التفاعل
class DrugInteractionResult {
  final bool hasInteraction;
  final InteractionSeverity severity;
  final String? description;
  final String? recommendation;
  final String? mechanism;
  final String drug1;
  final String drug2;

  DrugInteractionResult({
    required this.hasInteraction,
    required this.severity,
    this.description,
    this.recommendation,
    this.mechanism,
    required this.drug1,
    required this.drug2,
  });

  /// 🔴 هل التفاعل حرج؟
  bool get isCritical => severity == InteractionSeverity.critical;

  /// 🟠 هل التفاعل مرتفع؟
  bool get isHigh => severity == InteractionSeverity.high;

  /// 📝 الرسالة السريرية
  String get clinicalMessage {
    if (!hasInteraction) return 'لا توجد تفاعلات معروفة';

    final prefix = switch (severity) {
      InteractionSeverity.critical => '🚨 تفاعل حرج:',
      InteractionSeverity.high => '🔴 تفاعل مرتفع:',
      InteractionSeverity.moderate => '🟡 تفاعل معتدل:',
      InteractionSeverity.low => '🔵 تفاعل منخفض:',
      InteractionSeverity.none => '✅ لا توجد مشاكل',
    };

    return '$prefix $description\n💡 التوصية: $recommendation';
  }
}

/// 🎯 مستويات حدة التفاعل
enum InteractionSeverity {
  none, // لا توجد
  low, // منخفض
  moderate, // معتدل
  high, // مرتفع
  critical, // حرج
}

/// 📊 إحصائيات التفاعلات
class InteractionStatistics {
  final int totalInteractions;
  final int criticalCount;
  final int highCount;
  final int moderateCount;
  final int lowCount;
  final List<DrugInteractionResult> interactions;

  InteractionStatistics({
    required this.totalInteractions,
    required this.criticalCount,
    required this.highCount,
    required this.moderateCount,
    required this.lowCount,
    required this.interactions,
  });

  /// 🚨 هل توجد تفاعلات حرجة؟
  bool get hasCriticalInteractions => criticalCount > 0;

  /// 📈 الحصول على النسبة المئوية للخطورة
  double get riskPercentage {
    if (totalInteractions == 0) return 0;
    return ((criticalCount * 5 + highCount * 3 + moderateCount * 1) /
            (totalInteractions * 5)) *
        100;
  }
}
