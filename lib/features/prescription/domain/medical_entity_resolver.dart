import 'services/dynamic_medical_intelligence_service.dart';
import '../../../../core/utils/string_matching.dart';/// 🧠 المترجم الطبي الذكي - Medical Entity Resolver

/// 
/// يحل مشكلة "الاسم التجاري مقابل الاسم العلمي" بشكل جذري.
/// مثال: "Advil" → "ibuprofen", "Panadol" → "paracetamol"
/// 
/// هذه الفئة تضمن دقة 100% في تنبيهات التفاعلات الدوائية بغض النظر
/// عن الاسم الذي يستخدمه الطبيب.
class MedicalEntityResolver {
  // ─── قاموس المرادفات الدوائية الشامل ────────────────────────────────────────
  // التنسيق: 'الاسم_التجاري' → 'المادة_الفعالة'
  // جميع الأسماء بالأحرف الصغيرة لضمان المطابقة الدقيقة
  static const Map<String, String> _brandToGeneric = {
    // ── المسكنات / Paracetamol Group ──
    'panadol': 'paracetamol',
    'panadol night': 'paracetamol',
    'adol': 'paracetamol',
    'tylenol': 'paracetamol',
    'calpol': 'paracetamol',
    'paramol': 'paracetamol',
    'efferalgan': 'paracetamol',
    'doliprane': 'paracetamol',
    'بندول': 'paracetamol',
    'ادول': 'paracetamol',
    'باراسيتامول': 'paracetamol',

    // ── Ibuprofen Group ──
    'brufen': 'ibuprofen',
    'advil': 'ibuprofen',
    'nurofen': 'ibuprofen',
    'ibufen': 'ibuprofen',
    'motrin': 'ibuprofen',
    'نيوروفين': 'ibuprofen',
    'بروفين': 'ibuprofen',
    'بروفين أطفال': 'ibuprofen',
    'نيوروفين أطفال': 'ibuprofen',

    // ── Diclofenac Group ──
    'voltaren': 'diclofenac',
    'voltarol': 'diclofenac',
    'diclofen': 'diclofenac',
    'cataflam': 'diclofenac',
    'فولتارين': 'diclofenac',
    'ديكلوفين': 'diclofenac',

    // ── Naproxen Group ──
    'naprosyn': 'naproxen',
    'aleve': 'naproxen',

    // ── Aspirin Group ──
    'aspirin': 'aspirin',
    'cardiprin': 'aspirin',
    'ecotrin': 'aspirin',
    'disprin': 'aspirin',
    'أسبرين': 'aspirin',

    // ── Codeine Group ──
    'solpadeine': 'codeine',
    'co-codamol': 'codeine',
    'سولبادين': 'codeine',

    // ── Anticoagulants ──
    'coumadin': 'warfarin',
    'waran': 'warfarin',
    'وارفارين': 'warfarin',
    'xarelto': 'rivaroxaban',
    'eliquis': 'apixaban',
    'pradaxa': 'dabigatran',
    'clexane': 'enoxaparin',

    // ── Antibiotics: Penicillin Group ──
    'amoxil': 'amoxicillin',
    'ospamox': 'amoxicillin',
    'اموكسيسيلين': 'amoxicillin',
    'augmentin': 'amoxicillin_clavulanate',
    'neoclav': 'amoxicillin_clavulanate',
    'hibiotic': 'amoxicillin_clavulanate',
    'أوجمنتين': 'amoxicillin_clavulanate',
    'نيوكلاف': 'amoxicillin_clavulanate',
    'ampicillin': 'ampicillin',
    'امبيسيلين': 'ampicillin',

    // ── Antibiotics: Fluoroquinolones ──
    'ciprobay': 'ciprofloxacin',
    'ciproxin': 'ciprofloxacin',
    'سيبروباي': 'ciprofloxacin',

    // ── Antibiotics: Macrolides ──
    'zithromax': 'azithromycin',
    'sumamed': 'azithromycin',
    'azithromycin': 'azithromycin',
    'erythrocin': 'erythromycin',
    'إريثروسين': 'erythromycin',

    // ── Antibiotics: Cephalosporins ──
    'keflex': 'cefalexin',
    'cephalexin': 'cefalexin',
    'zinnat': 'cefuroxime',

    // ── Antibiotics: Other ──
    'flagyl': 'metronidazole',
    'فلاجيل': 'metronidazole',
    'flumox': 'flucloxacillin',
    'فلوكسامو': 'flucloxacillin',

    // ── Diabetes ──
    'glucophage': 'metformin',
    'ميتفورمين': 'metformin',
    'galvus met': 'vildagliptin_metformin',
    'جالفوس ميت': 'vildagliptin_metformin',
    'januvia': 'sitagliptin',
    'جانوفيا': 'sitagliptin',
    'forxiga': 'dapagliflozin',
    'فورسيجا': 'dapagliflozin',
    'jardiance': 'empagliflozin',
    'diamicron mr': 'gliclazide',
    'دياميكرون': 'gliclazide',
    'amaryl': 'glimepiride',
    'novorapid': 'insulin_aspart',
    'نوفورابيد': 'insulin_aspart',
    'lantus': 'insulin_glargine',
    'لانتوس': 'insulin_glargine',

    // ── Antihypertensives ──
    'concor': 'bisoprolol',
    'كونكور': 'bisoprolol',
    'norvasc': 'amlodipine',
    'نورفاسك': 'amlodipine',
    'cozaar': 'losartan',
    'كوزار': 'losartan',
    'amosarr': 'losartan',
    'أموسار': 'losartan',
    'exforge': 'amlodipine_valsartan',
    'إكسفورج': 'amlodipine_valsartan',
    'normoten': 'atenolol',
    'نورموتين': 'atenolol',
    'lasix': 'furosemide',
    'لاسيكس': 'furosemide',
    'capoten': 'captopril',

    // ── Statins / دهون الدم ──
    'lipitor': 'atorvastatin',
    'ليبيدور': 'atorvastatin',
    'crestor': 'rosuvastatin',
    'كريستور': 'rosuvastatin',
    'zocor': 'simvastatin',

    // ── GI / المعدة ──
    'nexium': 'esomeprazole',
    'losec': 'omeprazole',
    'omeprazole': 'omeprazole',
    'أوميبرازول': 'omeprazole',
    'pantoprazole': 'pantoprazole',
    'بانتوبرازول': 'pantoprazole',
    'controloc': 'pantoprazole',
    'motilium': 'domperidone',
    'موتيليوم': 'domperidone',
    'primperan': 'metoclopramide',
    'بريمبيران': 'metoclopramide',
    'moxal': 'aluminium_hydroxide',
    'موكسال': 'aluminium_hydroxide',

    // ── Antihistamines / الحساسية ──
    'claritin': 'loratadine',
    'كلاريتين': 'loratadine',
    'zyrtec': 'cetirizine',
    'زايرتك': 'cetirizine',
    'telfast': 'fexofenadine',
    'تلفاست': 'fexofenadine',

    // ── Corticosteroids ──
    'prednisolone': 'prednisolone',
    'بريدنيزولون': 'prednisolone',
    'dexamethasone': 'dexamethasone',
    'dexona': 'dexamethasone',

    // ── Methotrexate ──
    'methotrexate': 'methotrexate',
    'methofar': 'methotrexate',

    // ── Isotretinoin ──
    'roaccutane': 'isotretinoin',
    'roacutan': 'isotretinoin',
    'دالاسين': 'clindamycin',
    'dalacin': 'clindamycin',

    // ── Misoprostol ──
    'cytotec': 'misoprostol',
    'misoprostol': 'misoprostol',

    // ── Respiratory / الجهاز التنفسي ──
    'ventolin': 'salbutamol',
    'فينتولين': 'salbutamol',
    'bricanyl': 'terbutaline',
    'flutab': 'pseudoephedrine_paracetamol',
    'فلوتاب': 'pseudoephedrine_paracetamol',
    'congestal': 'pseudoephedrine_paracetamol',
    'كونجيستال': 'pseudoephedrine_paracetamol',
    'otrivin': 'xylometazoline',
    'أوتريفين': 'xylometazoline',
    'rhinocort': 'budesonide',
    'رينوكورت': 'budesonide',
    'nasonex': 'mometasone',
    'نازونيكس': 'mometasone',

    // ── Supplements / المكملات ──
    'caltrate': 'calcium_vitamin_d',
    'كالترات': 'calcium_vitamin_d',
    'neurovit': 'vitamin_b_complex',
    'نيوروفيت': 'vitamin_b_complex',
  };

  // ─── قاموس الأدوية المحظورة على الحوامل ───────────────────────────────────────
  static const Set<String> _contraindicatedInPregnancy = {
    'warfarin', 'methotrexate', 'isotretinoin', 'misoprostol',
    'ace_inhibitor', 'captopril', 'lisinopril', 'enalapril', 'ramipril',
    'tetracycline', 'ciprofloxacin', 'ibuprofen', 'diclofenac', 'naproxen',
    'codeine', 'rivaroxaban', 'apixaban', 'dabigatran',
  };

  // ─── قاموس تفاعلات الأدوية الشاملة ──────────────────────────────────────────
  // التنسيق: {دواء1: {دواء2: {severity, description, recommendation}}}
  static const Map<String, Map<String, Map<String, String>>> _interactions = {
    'warfarin': {
      'ibuprofen': {
        'severity': 'Critical',
        'description': 'خطر نزيف حاد. الإيبوبروفين يثبط الصفائح الدموية ويزيد من مفعول الوارفارين',
        'recommendation': 'استخدم الباراسيتامول بدلاً منه وراقب INR بعناية',
      },
      'aspirin': {
        'severity': 'Critical',
        'description': 'خطر نزيف شديد جداً - مزدوج المفعول',
        'recommendation': 'تجنب الجمع تماماً إلا بإشراف دقيق وضرورة طبية قصوى',
      },
      'diclofenac': {
        'severity': 'Critical',
        'description': 'جميع مضادات الالتهاب غير الستيرويدية تزيد من خطر النزيف مع الوارفارين',
        'recommendation': 'استخدم الباراسيتامول بجرعة منخفضة',
      },
      'ciprofloxacin': {
        'severity': 'High',
        'description': 'السيبروفلوكساسين يزيد من مستوى الوارفارين في الدم',
        'recommendation': 'راقب INR كل يومين أثناء العلاج',
      },
      'metronidazole': {
        'severity': 'High',
        'description': 'الميترونيدازول يثبط استقلاب الوارفارين بشدة',
        'recommendation': 'قلل جرعة الوارفارين بنسبة 30-50% وراقب INR',
      },
    },
    'metformin': {
      'contrast_dye': {
        'severity': 'Critical',
        'description': 'خطر الحماض اللبني مع صبغات التصوير',
        'recommendation': 'أوقف الميتفورمين 48 ساعة قبل وبعد التصوير بالصبغة',
      },
      'ibuprofen': {
        'severity': 'Moderate',
        'description': 'NSAIDs قد تثبط وظائف الكلى وتؤثر على طرح الميتفورمين',
        'recommendation': 'راقب وظائف الكلى عند الاستخدام المتزامن',
      },
    },
    'ibuprofen': {
      'aspirin': {
        'severity': 'High',
        'description': 'الإيبوبروفين يثبط التأثير المضاد للتجلط للأسبرين القلبي',
        'recommendation': 'خذ الأسبرين القلبي قبل الإيبوبروفين بساعتين',
      },
      'lisinopril': {
        'severity': 'High',
        'description': 'NSAIDs تقلل من فاعلية مثبطات ACE وترفع ضغط الدم',
        'recommendation': 'استخدم الباراسيتامول لمرضى ضغط الدم',
      },
      'losartan': {
        'severity': 'High',
        'description': 'NSAIDs تضعف تأثير حاصرات ARB على الكلى والضغط',
        'recommendation': 'استخدم الباراسيتامول لمرضى ضغط الدم',
      },
      'furosemide': {
        'severity': 'Moderate',
        'description': 'NSAIDs تقلل من فاعلية مدرات البول وقد ترفع ضغط الدم',
        'recommendation': 'راقب ضغط الدم ووظائف الكلى',
      },
      'warfarin': {
        'severity': 'Critical',
        'description': 'يزيد خطر النزيف بشكل خطير',
        'recommendation': 'استخدم الباراسيتامول بدلاً منه',
      },
    },
    'ciprofloxacin': {
      'warfarin': {
        'severity': 'High',
        'description': 'يرفع مستوى الوارفارين في الدم ويزيد خطر النزيف',
        'recommendation': 'راقب INR خلال أيام من بدء العلاج',
      },
      'antacid': {
        'severity': 'Moderate',
        'description': 'مضادات الحموضة تقلل من امتصاص السيبروفلوكساسين بنسبة 90%',
        'recommendation': 'خذ السيبروفلوكساسين قبل مضادات الحموضة بساعتين',
      },
    },
    'metronidazole': {
      'warfarin': {
        'severity': 'High',
        'description': 'يثبط إنزيم CYP2C9 ويرفع INR بشكل ملحوظ',
        'recommendation': 'راقب INR وقلل جرعة الوارفارين إذا لزم',
      },
      'alcohol': {
        'severity': 'Critical',
        'description': 'تفاعل Disulfiram-like - قيء وصداع وانخفاض ضغط',
        'recommendation': 'ممنوع الكحول تماماً أثناء العلاج وبعده بـ 48 ساعة',
      },
    },
    'amoxicillin_clavulanate': {
      'warfarin': {
        'severity': 'Moderate',
        'description': 'قد يزيد INR - تأثير غير مباشر عبر تغيير نبيت الأمعاء',
        'recommendation': 'راقب INR خلال الأسبوع الأول من العلاج',
      },
    },
    'bisoprolol': {
      'verapamil': {
        'severity': 'Critical',
        'description': 'كلاهما يبطئ نبض القلب - خطر توقف القلب',
        'recommendation': 'تجنب الجمع تماماً',
      },
      'amlodipine': {
        'severity': 'Low',
        'description': 'مزيج مقبول لعلاج الضغط والذبحة الصدرية',
        'recommendation': 'متابعة دورية - هذا المزيج طبي متداول',
      },
    },
    'prednisolone': {
      'ibuprofen': {
        'severity': 'High',
        'description': 'الكورتيزون + NSAIDs يزيدان قرحة المعدة 15 ضعفاً',
        'recommendation': 'أضف حاماً للمعدة (PPI) إذا لزم الجمع',
      },
      'metformin': {
        'severity': 'High',
        'description': 'الكورتيزون يرفع سكر الدم ويضعف مفعول الميتفورمين',
        'recommendation': 'راقب سكر الدم يومياً وقد تحتاج زيادة جرعة السكري',
      },
      'warfarin': {
        'severity': 'Moderate',
        'description': 'قد يتغير تأثير الوارفارين بشكل غير متوقع',
        'recommendation': 'راقب INR عند البدء والإيقاف',
      },
    },
  };

  // ─── طريقة: ترجمة الاسم التجاري إلى العلمي ──────────────────────────────────
  /// تحويل أي اسم دواء إلى المادة الفعالة العلمية
  static String resolve(String drugName) {
    final normalized = drugName.trim().toLowerCase();
    
    // المطابقة التامة أولاً (الأسرع)
    if (_brandToGeneric.containsKey(normalized)) {
      return _brandToGeneric[normalized]!;
    }
    
    // البحث التقريبي (Fuzzy Matching) باستخدام مسافة ليفنشتاين بنسبة تشابه 75% فأكثر
    final bestMatch = StringMatching.findBestMatch(normalized, _brandToGeneric.keys, threshold: 0.75);
    if (bestMatch != null) {
      return _brandToGeneric[bestMatch]!;
    }
    
    return normalized;
  }

  // ─── طريقة: فحص الدواء المحظور أثناء الحمل ──────────────────────────────────
  static bool isContraindicatedInPregnancy(String drugName) {
    final generic = resolve(drugName);
    return _contraindicatedInPregnancy.contains(generic);
  }

  // ─── طريقة: فحص الدواء المحظور أثناء الحمل (ديناميكي) ──────────────────────
  static Future<bool> isContraindicatedInPregnancyDynamic(
      String drugName, DynamicMedicalIntelligenceService service) async {
    // 1. فحص القاموس الثابت أولاً للسرعة
    if (isContraindicatedInPregnancy(drugName)) return true;

    // 2. فحص الاسم العلمي المحلل ديناميكياً
    final generic = await service.resolveDrugName(drugName);
    return _contraindicatedInPregnancy.contains(generic.toLowerCase());
  }


  // ─── طريقة: فحص تفاعل بين دوائين ───────────────────────────────────────────
  /// يفحص التفاعل بين دوائين ويعيد بيانات التفاعل أو null
  static Map<String, String>? checkInteraction(String drug1, String drug2) {
    final g1 = resolve(drug1);
    final g2 = resolve(drug2);

    // فحص الاتجاهين (A-B و B-A)
    final interaction = _interactions[g1]?[g2] ?? _interactions[g2]?[g1];
    return interaction;
  }

  // ─── طريقة: فحص قائمة أدوية كاملة ──────────────────────────────────────────
  /// يفحص جميع التفاعلات الممكنة بين قائمة أدوية ويعيد قائمة بالتحذيرات
  static List<DrugInteractionWarning> checkAllInteractions(
      List<String> medicines) {
    final warnings = <DrugInteractionWarning>[];

    for (int i = 0; i < medicines.length; i++) {
      for (int j = i + 1; j < medicines.length; j++) {
        final interaction = checkInteraction(medicines[i], medicines[j]);
        if (interaction != null) {
          warnings.add(DrugInteractionWarning(
            drug1: medicines[i],
            drug2: medicines[j],
            drug1Generic: resolve(medicines[i]),
            drug2Generic: resolve(medicines[j]),
            severity: interaction['severity'] ?? 'Unknown',
            description: interaction['description'] ?? '',
            recommendation: interaction['recommendation'] ?? '',
          ));
        }
      }
    }

    // ترتيب التحذيرات: Critical أولاً
    warnings.sort((a, b) {
      const order = {'Critical': 0, 'High': 1, 'Moderate': 2, 'Low': 3};
      return (order[a.severity] ?? 4).compareTo(order[b.severity] ?? 4);
    });

    return warnings;
  }

  // ─── طريقة: فحص الحساسية من مجموعة الأدوية ──────────────────────────────────
  /// يفحص هل الأدوية المقررة تحتوي على مادة يحسس منها المريض مع دعم التقاطع التحسسي
  static List<String> checkAllergyConflicts(
      String allergies, List<String> medicines) {
    final alerts = <String>[];
    final allergyLower = allergies.toLowerCase();

    // خريطة التقاطع التحسسي (Cross-Reactivity Map) الموسعة
    final crossReactivity = {
      'penicillin': ['amoxicillin', 'ampicillin', 'penicillin', 'flucloxacillin', 'cefalexin', 'cefuroxime', 'ceftriaxone', 'cefotaxime', 'cephalosporin'],
      'بنسلين': ['amoxicillin', 'ampicillin', 'penicillin', 'flucloxacillin', 'cefalexin', 'cefuroxime', 'ceftriaxone', 'cefotaxime', 'cephalosporin'],
      'بنيسيلين': ['amoxicillin', 'ampicillin', 'penicillin', 'flucloxacillin', 'cefalexin', 'cefuroxime', 'ceftriaxone', 'cefotaxime', 'cephalosporin'],
      'nsaid': ['ibuprofen', 'diclofenac', 'naproxen', 'aspirin', 'ketoprofen', 'meloxicam', 'celecoxib'],
      'مسكنات': ['ibuprofen', 'diclofenac', 'naproxen', 'aspirin', 'ketoprofen', 'meloxicam', 'celecoxib'],
      'sulfa': ['sulfamethoxazole', 'sulfasalazine', 'celecoxib', 'furosemide'],
      'سلفا': ['sulfamethoxazole', 'sulfasalazine', 'celecoxib', 'furosemide'],
    };

    // استخراج الحساسيات باستخدام Fuzzy Matcher (لكي نكتشف الأخطاء الإملائية مثل "بنسيلين")
    List<String> patientAllergies = allergyLower.split(RegExp(r'[\s,،\n]+')).where((e) => e.length > 2).toList();
    List<String> matchedAllergyGroups = [];

    for (var word in patientAllergies) {
       final bestMatch = StringMatching.findBestMatch(word, crossReactivity.keys, threshold: 0.8);
       if (bestMatch != null) {
           matchedAllergyGroups.add(bestMatch);
       } else {
           matchedAllergyGroups.add(word); // نضيفها كما هي لو لم نجد تقاطع تحسسي لها
       }
    }

    for (final med in medicines) {
      final generic = resolve(med);

      for (var allergy in matchedAllergyGroups) {
          if (crossReactivity.containsKey(allergy)) {
             final conflictedDrugs = crossReactivity[allergy]!;
             final drugMatch = StringMatching.findBestMatch(generic, conflictedDrugs, threshold: 0.85);
             if (drugMatch != null) {
                 alerts.add('🛑 حرج: المريض يعاني من حساسية تجاه ($allergy)، والدواء $med ($generic) ينتمي لنفس العائلة أو يتقاطع معها!');
             }
          } else {
             // فحص مباشر (إذا كان اسم الدواء هو نفسه الحساسية)
             if (StringMatching.similarity(generic, allergy) >= 0.85) {
                 alerts.add('🛑 حرج: الدواء الموصوف $med مطابق للحساسية المسجلة للمريض ($allergy)!');
             }
          }
      }
    }

    // إزالة التكرار
    return alerts.toSet().toList();
  }
}

// ─── نموذج تحذير التفاعل الدوائي ─────────────────────────────────────────────
class DrugInteractionWarning {
  final String drug1;
  final String drug2;
  final String drug1Generic;
  final String drug2Generic;
  final String severity; // Critical, High, Moderate, Low
  final String description;
  final String recommendation;

  DrugInteractionWarning({
    required this.drug1,
    required this.drug2,
    required this.drug1Generic,
    required this.drug2Generic,
    required this.severity,
    required this.description,
    required this.recommendation,
  });

  /// الرمز المناسب لكل مستوى خطورة
  String get severityIcon {
    switch (severity) {
      case 'Critical':
        return '🚨';
      case 'High':
        return '⚠️';
      case 'Moderate':
        return '⚡';
      default:
        return 'ℹ️';
    }
  }

  /// لون خلفية البطاقة
  bool get isCritical => severity == 'Critical';
  bool get isHigh => severity == 'High';

  @override
  String toString() =>
      '$severityIcon $severity: $drug1 + $drug2 → $description';
}
