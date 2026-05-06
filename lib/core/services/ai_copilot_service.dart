import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/clinical_ai_prompts.dart';
import '../../features/patient/domain/entities/patient_entity.dart';
import '../../features/doctor/domain/entities/doctor_entity.dart';

/// رسالة داخل المحادثة
class CopilotMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  CopilotMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// خدمة المساعد الطبي الذكي (Chat-based Copilot)
class AiCopilotService {
  final List<CopilotMessage> _messages = [];
  // System prompt يُستخدم عند الاتصال بـ API الفعلي
  String _systemPrompt = '';

  List<CopilotMessage> get messages => List.unmodifiable(_messages);

  /// تهيئة المحادثة بحقن بيانات المريض والطبيب.
  /// [vitals] تُمرَّر من آخر وصفة (اختياري)
  void initializeContext({
    required PatientEntity patient,
    required DoctorEntity doctor,
    Map<String, dynamic>? vitals,
  }) {
    _messages.clear();

    _systemPrompt = ClinicalAiPrompts.getSystemPrompt(
      patientName: patient.name,
      age: patient.age ?? 0,
      ageCategory: _ageCatLabel(patient.ageCategory),
      gender: patient.gender ?? 'غير محدد',
      isPregnant: patient.isPregnant,
      chronicDiseases: patient.chronicDiseases ?? '',
      allergies: patient.allergies ?? '',
      currentMedications: patient.currentMedicationsJson,
      systolic: vitals?['systolic'] as double?,
      diastolic: vitals?['diastolic'] as double?,
      pulse: vitals?['pulse'] as int?,
      bloodSugar: vitals?['sugar'] as double?,
      weight: vitals?['weight'] as double?,
      height: patient.height,
      temperature: vitals?['temperature'] as double?,
      diagnosis: (vitals?['diagnosis'] as String?) ?? 'غير محدد',
      specialty: doctor.specialty ?? 'طبيب عام',
    );

    _messages.add(CopilotMessage(
      text: 'أهلاً دكتور ${doctor.name}. المساعد السريري جاهز.\n'
          'لقد قمت بتحليل السجل الطبي للمريض (${patient.name}). '
          'كيف يمكنني المساعدة في خطة العلاج؟',
      isUser: false,
    ));
  }

  /// إرسال رسالة إلى المساعد والحصول على رد
  Future<void> sendMessage(String text, void Function() onUpdate) async {
    _messages.add(CopilotMessage(text: text, isUser: true));
    onUpdate();

    _messages.add(CopilotMessage(text: '...', isUser: false));
    onUpdate();

    // TODO: استبدل هذا باستدعاء Gemini / ChatGPT API مع _systemPrompt
    await Future.delayed(const Duration(seconds: 2));

    _messages.removeLast();
    _messages.add(CopilotMessage(text: _buildResponse(text), isUser: false));
    onUpdate();
  }

  /// ردود سياقية ذكية (تُستبدل بـ LLM حقيقي لاحقاً)
  String _buildResponse(String userInput) {
    final lower = userInput.toLowerCase();

    if (lower.contains('حمل') || lower.contains('حامل') || lower.contains('pregnant')) {
      return '[🚨 CRITICAL]: المريضة حامل! يُحظر تماماً وصف الأدوية من فئة D أو X '
          '(Roaccutane, Tetracycline, Warfarin, Methotrexate).\n\n'
          'البديل الآمن: Amoxicillin 500mg/8h أو Cephalexin 500mg/8h للعدوى.\n\n'
          'المصدر: FDA Pregnancy Categories.';
    } else if (lower.contains('ibuprofen') || lower.contains('بروفين') || lower.contains('nsaid')) {
      return '[🔴 HIGH]: الـ NSAIDs (إيبوبروفين، ديكلوفيناك) ترفع ضغط الدم وتضر بوظائف الكلى.\n\n'
          'التوصية: Paracetamol 1g كل 6 ساعات كمسكن آمن.\n\n'
          'المصدر: BNF - Analgesics.';
    } else if (lower.contains('ضغط') || lower.contains('hypertension')) {
      return '[🔴 HIGH]: تجنب الـ NSAIDs وأدوية الاحتقان التي تحتوي Pseudoephedrine.\n\n'
          'التوصية: راجع خطة أدوية الضغط (ACE inhibitor أو ARB).\n\n'
          'المصدر: JNC 8 Guidelines.';
    } else if (lower.contains('طفل') || lower.contains('جرعة') || lower.contains('وزن') || lower.contains('kg')) {
      return '[💡 NOTE]: جرعات الأطفال الموصى بها:\n'
          '• باراسيتامول: 10-15 mg/kg/dose كل 6-8 ساعات\n'
          '• إيبوبروفين: 5-10 mg/kg/dose كل 6-8 ساعات\n'
          '• أموكسيسيلين: 40-90 mg/kg/day مقسمة على 3 جرعات\n\n'
          'المصدر: BNF for Children (2024).';
    } else if (lower.contains('تفاعل') || lower.contains('interaction')) {
      return '[💡 NOTE]: يقوم النظام تلقائياً بفحص التفاعلات الدوائية عند إضافة أي دواء.\n'
          'إذا أردت فحصاً يدوياً، اذكر اسمي الدوائين وسأحلل التفاعل فوراً.';
    } else {
      return 'لقد راجعت الملف السريري كاملاً. لم أجد موانع واضحة للخطة المقترحة.\n\n'
          '[💡 NOTE]: تذكر مراجعة الحساسيات والأمراض المزمنة قبل الوصف النهائي.\n\n'
          'هل تريد تفاصيل حول دواء أو تفاعل محدد؟';
    }
  }

  String _ageCatLabel(int? cat) {
    switch (cat) {
      case 0: return 'رضيع';
      case 1: return 'طفل';
      case 2: return 'بالغ';
      case 3: return 'مسن';
      default: return 'غير محدد';
    }
  }
}

final aiCopilotServiceProvider = Provider<AiCopilotService>((ref) {
  return AiCopilotService();
});
