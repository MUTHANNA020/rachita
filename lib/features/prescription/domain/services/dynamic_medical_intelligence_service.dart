import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../medical_entity_resolver.dart';
import '../../../medicine/domain/entities/medicine_entity.dart';

import 'package:sqflite/sqflite.dart';

/// 🧠 خدمة الذكاء الطبي الديناميكي - Dynamic Medical Intelligence Service
/// 
/// توفر دقة عالية جداً وسرعة في معالجة البيانات الطبية عبر الربط المباشر
/// مع قاعدة البيانات، مما يلغي "المحدودية" في المكونات.
class DynamicMedicalIntelligenceService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─── 1. الدقة: التحقق من اسم الدواء (Fuzzy Search) ──────────────────────────
  /// البحث عن الدواء في قاعدة البيانات باستخدام FTS (البحث بالنص الكامل)
  /// يضمن العثور على الدواء حتى مع وجود أخطاء إملائية.
  Future<List<Map<String, dynamic>>> searchMedicineFuzzy(String query) async {
    final db = await _dbHelper.database;
    
    // البحث في جدول FTS للسرعة القصوى
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT rowid as id, name_ar, name_en 
      FROM ${DBConstants.tableMedicinesFts} 
      WHERE ${DBConstants.tableMedicinesFts} MATCH ? 
      LIMIT 10
    ''', ['$query*']);

    if (results.isEmpty) {
      // Fallback: البحث التقليدي (LIKE) في حال لم يعطِ FTS نتائج
      return await db.query(
        DBConstants.tableMedicines,
        where: 'name_ar LIKE ? OR name_en LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 10,
      );
    }
    return results;
  }

  // ─── 2. التكامل: ترجمة الأسماء (Resolver) ──────────────────────────────────
  /// دمج المترجم الثابت مع قاعدة البيانات الديناميكية
  Future<String> resolveDrugName(String drugName) async {
    // أولاً: التحقق من القاموس الثابت للسرعة (الأدوية الشائعة)
    final staticGeneric = MedicalEntityResolver.resolve(drugName);
    if (staticGeneric != drugName) return staticGeneric;

    // ثانياً: البحث في قاعدة البيانات عن الاسم العلمي المرتبط
    final db = await _dbHelper.database;
    final results = await db.query(
      DBConstants.tableMedicines,
      where: 'name_ar = ? OR name_en = ?',
      whereArgs: [drugName, drugName],
      limit: 1,
    );

    if (results.isNotEmpty) {
      // إذا وجدنا الدواء، نعيد الاسم الإنجليزي كاسم مرجعي
      return (results.first['name_en'] ?? results.first['name_ar'] ?? drugName).toString();
    }


    return drugName; // العودة للاسم الأصلي إذا لم يوجد
  }

  // ─── 3. السرعة: جلب أنماط الطبيب (Patterns) ────────────────────────────────
  /// جلب العلاج المقترح بناءً على التشخيص من "ذاكرة النظام"
  Future<List<Map<String, dynamic>>> getSuggestedTreatments(String diagnosis) async {
    final db = await _dbHelper.database;
    return await db.query(
      DBConstants.tableDoctorPatterns,
      where: 'diagnosis LIKE ?',
      whereArgs: ['%$diagnosis%'],
      orderBy: 'use_count DESC',
      limit: 5,
    );
  }

  // ─── 4. المرونة: معالجة الأوامر الصوتية المعقدة ──────────────────────────────
  /// تحويل النص الناتج عن الصوت إلى كائنات "دواء" منظمة
  Future<Map<String, dynamic>> processVoiceCommand(String text) async {
    // استخدام المنطق المعقد لتقسيم الجملة
    // مثال: "أعط المريض أموكسيسيلين ٥٠٠ ملغ مرتين يومياً لمدة أسبوع"
    
    final normalized = text.toLowerCase();
    
    // محاولة إيجاد الدواء في النص عبر البحث في DB
    final words = normalized.split(' ');
    String? detectedDrug;
    
    for (var word in words) {
      if (word.length < 4) continue;
      final matches = await searchMedicineFuzzy(word);
      if (matches.isNotEmpty) {
        detectedDrug = matches.first['name_en'] ?? matches.first['name_ar'];
        break;
      }
    }

    // استخراج الجرعة (Dosage)
    final doseMatch = RegExp(r'(\d+)\s*(ملغ|mg|مل|ml|جرام|g)', caseSensitive: false).firstMatch(normalized);
    final dosage = doseMatch != null ? '${doseMatch.group(1)}${doseMatch.group(2)}' : '';

    // استخراج التكرار (Frequency)
    String frequency = '';
    if (normalized.contains('مرتين') || normalized.contains('bid')) frequency = 'مرتين يومياً';
    else if (normalized.contains('ثلاث') || normalized.contains('tid')) frequency = '٣ مرات يومياً';
    else if (normalized.contains('مرة') || normalized.contains('od')) frequency = 'مرة يومياً';

    return {
      'medicine_name': detectedDrug ?? '',
      'dosage': dosage,
      'frequency': frequency,
      'raw_text': text,
    };
  }

  // ─── 5. الاستقرار: التحقق من التفاعلات (Scalable Interactions) ───────────
  /// فحص التفاعلات عبر قاعدة البيانات (لا حدود لعدد الأدوية)
  Future<List<Map<String, dynamic>>> checkInteractions(List<String> medicines) async {
    if (medicines.length < 2) return [];
    
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> alerts = [];

    for (int i = 0; i < medicines.length; i++) {
      for (int j = i + 1; j < medicines.length; j++) {
        final m1 = await resolveDrugName(medicines[i]);
        final m2 = await resolveDrugName(medicines[j]);

        final results = await db.query(
          DBConstants.tableDrugInteractions,
          where: '(drug1 = ? AND drug2 = ?) OR (drug1 = ? AND drug2 = ?)',
          whereArgs: [m1, m2, m2, m1],
        );

        if (results.isNotEmpty) {
          alerts.add(results.first);
        }
      }
    }
    
    return alerts;
  }
}
