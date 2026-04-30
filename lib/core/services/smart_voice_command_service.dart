import '../../features/prescription/domain/services/dynamic_medical_intelligence_service.dart';
import '../../features/prescription/domain/medical_entity_resolver.dart';
import '../utils/medical_speech_normalizer.dart';

/// 🎙️ خدمة الأوامر الصوتية الذكية — مُحسّنة بـ NLP Parser
///
/// تحليل الأوامر الطبيعية مثل:
///   "صرف بروفين 400 مرتين يومياً لمدة 5 أيام"
///   "تشخيص التهاب الحلق الحاد"
///   "أضف باراسيتامول ألف ملغ كل 8 ساعات"
class SmartVoiceCommandService {
  final DynamicMedicalIntelligenceService _dynamicService;

  SmartVoiceCommandService(this._dynamicService);

  // ─── Keywords ──────────────────────────────────────────────────────────────
  static const _prescribeKw = ['اكتب', 'صرف', 'أضف', 'وصف', 'prescribe', 'add'];
  static const _diagnoseKw = ['تشخيص', 'المريض يعاني', 'diagnosis', 'يشكو من', 'عنده'];
  static const _saveKw = ['احفظ', 'save', 'حفظ'];
  static const _printKw = ['اطبع', 'print', 'طباعة'];
  static const _clearKw = ['امسح', 'clear', 'أعد', 'إعادة'];

  // ─── Frequency Synonyms ─────────────────────────────────────────────────────
  static const Map<String, String> _freqMap = {
    'مرة واحدة': 'مرة يومياً',
    'مرة يومياً': 'مرة يومياً',
    'مرة في اليوم': 'مرة يومياً',
    'مرتين': 'مرتين يومياً',
    'مرتين يومياً': 'مرتين يومياً',
    'مرتان': 'مرتين يومياً',
    'ثلاث مرات': 'ثلاث مرات يومياً',
    '3 مرات': 'ثلاث مرات يومياً',
    'كل 4 ساعات': 'كل 4 ساعات',
    'كل 6 ساعات': 'كل 6 ساعات',
    'كل 8 ساعات': 'كل 8 ساعات',
    'كل 12 ساعة': 'كل 12 ساعة',
    'كل يوم': 'مرة يومياً',
    'عند الحاجة': 'عند الحاجة (SOS)',
    'عند الألم': 'عند الحاجة (SOS)',
  };

  // ─── Duration Synonyms ──────────────────────────────────────────────────────
  static const Map<String, String> _durationPatterns = {
    'يوم': '1 يوم',
    'يومين': '2 يوم',
    '3 أيام': '3 أيام',
    'ثلاثة أيام': '3 أيام',
    '5 أيام': '5 أيام',
    'خمسة أيام': '5 أيام',
    'أسبوع': '7 أيام',
    'أسبوعين': '14 يوم',
    'شهر': '30 يوم',
  };

  /// تحليل النص الصوتي واستخراج القصد (Intent)
  Future<SmartCommandResult> processCommand(String rawText) async {
    final normalized = MedicalSpeechNormalizer.normalize(rawText);
    final lower = normalized.toLowerCase();

    // 1. مسح الوصفة
    if (_clearKw.any(lower.contains)) {
      return SmartCommandResult(intent: CommandIntent.clear, message: 'تم مسح الوصفة');
    }

    // 2. طباعة / حفظ
    if (_printKw.any(lower.contains)) {
      return SmartCommandResult(intent: CommandIntent.print, message: 'جاري تجهيز الطباعة...');
    }
    if (_saveKw.any(lower.contains)) {
      return SmartCommandResult(intent: CommandIntent.save, message: 'جاري حفظ الوصفة...');
    }

    // 3. وصف دواء — يستخدم NLP Parser الجديد
    if (_prescribeKw.any(lower.contains)) {
      final parsed = await _parsePrescriptionCommand(normalized);
      if (parsed['medicine_name'] != null) {
        return SmartCommandResult(
          intent: CommandIntent.prescribe,
          data: parsed,
          message: 'تمت إضافة: ${parsed['medicine_name']} ${parsed['dosage'] ?? ''}',
        );
      }
      // fallback للخدمة الديناميكية إذا فشل المحلل الهيكلي
      try {
        final dynamicParsed = await _dynamicService.processVoiceCommand(normalized);
        return SmartCommandResult(
          intent: CommandIntent.prescribe,
          data: dynamicParsed,
          message: 'تمت إضافة الدواء: ${dynamicParsed['medicine_name']}',
        );
      } catch (_) {}
    }

    // 4. تشخيص
    if (_diagnoseKw.any(lower.contains)) {
      final diagnosis = _extractDiagnosis(normalized);
      return SmartCommandResult(
        intent: CommandIntent.diagnose,
        data: {'diagnosis': diagnosis},
        message: 'التشخيص: $diagnosis',
      );
    }

    // 5. افتراضي: إملاء نصي
    return SmartCommandResult(
      intent: CommandIntent.dictation,
      data: {'text': normalized},
    );
  }

  /// 🧠 NLP Parser للأوامر الطبية
  /// يحلل: "بروفين 400 مرتين يومياً لمدة 5 أيام"
  Future<Map<String, dynamic>> _parsePrescriptionCommand(String text) async {
    String? medicineName;
    String? dosage;
    String? dosageUnit;
    String? frequency;
    String? duration;

    // ── استخراج اسم الدواء ──────────────────────────────────────────────────
    // 🆕 ذكاء حقيقي: بدلاً من قائمة ثابتة، نبحث في قاعدة البيانات لكل كلمة في الجملة!
    final words = text.split(' ');
    for (final word in words) {
      if (word.length < 3) continue; // تخطي حروف الجر
      
      // نستخدم FTS (البحث السريع جداً) للبحث في كامل قاعدة الأدوية
      final matches = await _dynamicService.searchMedicineFuzzy(word);
      if (matches.isNotEmpty) {
        // نأخذ أدق تطابق
        medicineName = (matches.first['name_en'] ?? matches.first['name_ar']).toString();
        break; // نتوقف عند أول دواء نجده
      }
    }

    // ── استخراج الجرعة (رقم قبل mg/ملغ/مل/وحدة) ─────────────────────────
    final dosageRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(mg|ملغ|ml|مل|mcg|unit|وحدة|iu)?', caseSensitive: false);
    final dosageMatch = dosageRegex.firstMatch(text);
    if (dosageMatch != null) {
      dosage = dosageMatch.group(1);
      dosageUnit = dosageMatch.group(2) ?? 'mg';
    }

    // ── استخراج التكرار ───────────────────────────────────────────────────
    _freqMap.forEach((pattern, value) {
      if (text.contains(pattern) && frequency == null) {
        frequency = value;
      }
    });

    // ── استخراج المدة ─────────────────────────────────────────────────────
    _durationPatterns.forEach((pattern, value) {
      if (text.contains(pattern) && duration == null) {
        duration = value;
      }
    });

    // ── استخراج المدة برقم (مثل "10 أيام") ──────────────────────────────
    if (duration == null) {
      final durRegex = RegExp(r'(\d+)\s*(يوم|أيام|يوماً|أسبوع|أسابيع|شهر)');
      final durMatch = durRegex.firstMatch(text);
      if (durMatch != null) {
        duration = '${durMatch.group(1)} ${durMatch.group(2)}';
      }
    }

    return {
      'medicine_name': medicineName,
      'dosage': dosage ?? '1',
      'dosage_unit': dosageUnit ?? 'mg',
      'frequency': frequency ?? 'مرة يومياً',
      'duration': duration ?? '5 أيام',
    };
  }

  // القائمة الثابتة محذوفة — النظام الآن ذكي بالكامل ويعتمد على قاعدة البيانات

  String _extractDiagnosis(String text) {
    for (final kw in _diagnoseKw) {
      if (text.contains(kw)) {
        final parts = text.split(kw);
        if (parts.length > 1) return parts.last.trim();
      }
    }
    return text.trim();
  }
}

enum CommandIntent { diagnose, prescribe, save, print, clear, dictation }

class SmartCommandResult {
  final CommandIntent intent;
  final Map<String, dynamic>? data;
  final String? message;
  SmartCommandResult({required this.intent, this.data, this.message});
}
