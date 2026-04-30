import 'package:uuid/uuid.dart';

class DrugInteractionSeeder {
  /// مستويات الخطورة (تتوافق مع InteractionSeverity enum)
  /// 0: None, 1: Low, 2: Moderate, 3: High, 4: Critical
  
  static List<Map<String, dynamic>> getInteractions() {
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();
    const clinicId = 'system_default'; // للتمييز أنها بيانات نظام

    final interactions = <Map<String, dynamic>>[
      // ─── مثبطات تخثر الدم ───
      _create(uuid, clinicId, now, 'warfarin', 'aspirin', 4, 
        'خطر نزيف شديد جداً. الإيبوبروفين والأسبرين يثبطان الصفائح الدموية ويزيدان من مفعول الوارفارين', 
        'تجنب الجمع تماماً إلا بإشراف دقيق وضرورة طبية قصوى'),
      _create(uuid, clinicId, now, 'warfarin', 'ibuprofen', 4, 
        'نزيف هضمي حاد. مضاد التهاب + مثبط تخثر = نزيف', 
        'استخدم الباراسيتامول بدلاً منه وراقب INR بعناية'),
      _create(uuid, clinicId, now, 'warfarin', 'diclofenac', 4, 
        'جميع مضادات الالتهاب غير الستيرويدية تزيد من خطر النزيف مع الوارفارين', 
        'استخدم الباراسيتامول بجرعة منخفضة'),
      _create(uuid, clinicId, now, 'warfarin', 'naproxen', 4, 
        'نزيف خطير جداً (مضاد التهاب قوي مع مثبط تخثر)', 
        'تجنب تماماً'),
      _create(uuid, clinicId, now, 'warfarin', 'ciprofloxacin', 3, 
        'السيبروفلوكساسين يزيد من مستوى الوارفارين في الدم', 
        'راقب INR كل يومين أثناء العلاج'),
      _create(uuid, clinicId, now, 'warfarin', 'metronidazole', 3, 
        'الميترونيدازول يثبط استقلاب الوارفارين بشدة', 
        'قلل جرعة الوارفارين بنسبة 30-50% وراقب INR'),

      // ─── الميتفورمين (علاج السكري) ───
      _create(uuid, clinicId, now, 'metformin', 'contrast_dye', 4, 
        'خطر الحماض اللبني مع صبغات التصوير (احتمال الفشل الكلوي الحاد)', 
        'أوقف الميتفورمين 48 ساعة قبل وبعد التصوير بالصبغة'),
      _create(uuid, clinicId, now, 'metformin', 'alcohol', 4, 
        'الحماض اللبني (Lactic Acidosis) - تفاعل قد يكون مميتاً', 
        'تجنب الكحول تماماً أثناء العلاج'),
      _create(uuid, clinicId, now, 'metformin', 'ibuprofen', 2, 
        'NSAIDs قد تثبط وظائف الكلى وتؤثر على طرح الميتفورمين', 
        'راقب وظائف الكلى عند الاستخدام المتزامن'),

      // ─── الإيبوبروفين / مضادات الالتهاب ───
      _create(uuid, clinicId, now, 'ibuprofen', 'aspirin', 3, 
        'الإيبوبروفين يثبط التأثير المضاد للتجلط للأسبرين القلبي', 
        'خذ الأسبرين القلبي قبل الإيبوبروفين بساعتين'),
      _create(uuid, clinicId, now, 'ibuprofen', 'lisinopril', 3, 
        'NSAIDs تقلل من فاعلية مثبطات ACE وترفع ضغط الدم وتسبب قصور كلوي حاد', 
        'استخدم الباراسيتامول لمرضى ضغط الدم'),
      _create(uuid, clinicId, now, 'ibuprofen', 'losartan', 3, 
        'NSAIDs تضعف تأثير حاصرات ARB على الكلى والضغط', 
        'استخدم الباراسيتامول لمرضى ضغط الدم'),
      _create(uuid, clinicId, now, 'ibuprofen', 'furosemide', 2, 
        'NSAIDs تقلل من فاعلية مدرات البول وقد ترفع ضغط الدم', 
        'راقب ضغط الدم ووظائف الكلى'),
      
      // ─── السيبروفلوكساسين ───
      _create(uuid, clinicId, now, 'ciprofloxacin', 'antacid', 2, 
        'مضادات الحموضة تقلل من امتصاص السيبروفلوكساسين بنسبة 90%', 
        'خذ السيبروفلوكساسين قبل مضادات الحموضة بساعتين'),
      
      // ─── الميترونيدازول ───
      _create(uuid, clinicId, now, 'metronidazole', 'alcohol', 4, 
        'تفاعل Disulfiram-like - قيء وصداع وانخفاض ضغط شديد', 
        'ممنوع الكحول تماماً أثناء العلاج وبعده بـ 48 ساعة'),

      // ─── أدوية القلب ───
      _create(uuid, clinicId, now, 'bisoprolol', 'verapamil', 4, 
        'كلاهما يبطئ نبض القلب - خطر توقف القلب', 
        'تجنب الجمع تماماً واستشر طبيب القلب'),
      _create(uuid, clinicId, now, 'bisoprolol', 'amlodipine', 1, 
        'مزيج مقبول لعلاج الضغط والذبحة الصدرية', 
        'متابعة دورية - هذا المزيج طبي متداول ومعتمد'),

      // ─── الستيرويدات (الكورتيزون) ───
      _create(uuid, clinicId, now, 'prednisolone', 'ibuprofen', 3, 
        'الكورتيزون + NSAIDs يزيدان احتمالية قرحة المعدة والنزيف الهضمي بمقدار 15 ضعفاً', 
        'أضف حامياً للمعدة (PPI) مثل أوميبرازول إذا لزم الجمع'),
      _create(uuid, clinicId, now, 'prednisolone', 'metformin', 3, 
        'الكورتيزون يرفع سكر الدم بقوة ويضعف مفعول الميتفورمين', 
        'راقب سكر الدم يومياً، قد تحتاج إلى زيادة جرعة السكري'),
      _create(uuid, clinicId, now, 'prednisolone', 'warfarin', 2, 
        'قد يتغير تأثير الوارفارين بشكل غير متوقع مع الستيرويدات', 
        'راقب INR عند البدء والإيقاف للستيرويد'),

      // ─── المضادات الحيوية ───
      _create(uuid, clinicId, now, 'amoxicillin', 'methotrexate', 3, 
        'زيادة خطيرة في سمية الميثوتريكسيت بسبب المنافسة على الإفراز الكلوي', 
        'تجنب الجمع، أو قلل جرعة الميثوتريكسيت بقوة'),
      _create(uuid, clinicId, now, 'amoxicillin_clavulanate', 'warfarin', 2, 
        'قد يزيد INR نتيجة تغيير نبيت الأمعاء وتأثيره على فيتامين K', 
        'راقب INR خلال الأسبوع الأول من العلاج'),

      // ─── الستاتينات (علاج الكوليسترول) ───
      _create(uuid, clinicId, now, 'atorvastatin', 'clarithromycin', 2, 
        'زيادة مستوى الستاتين في الدم (سمية عضلية) بسبب تثبيط إنزيم CYP3A4', 
        'قلل جرعة الستاتين أو استخدم مضاداً حيوياً بديلاً (مثل أزيثرومايسين)'),
      _create(uuid, clinicId, now, 'atorvastatin', 'diltiazem', 2, 
        'احتمالية ميوباثي (ضعف وألم عضلي) لزيادة مستوى الستاتين', 
        'راقب أعراض العضلات بانتظام'),
      _create(uuid, clinicId, now, 'simvastatin', 'ritonavir', 4, 
        'سمية عضلية وكبدية خطيرة جداً (تثبيط قوي لإنزيم CYP3A4)', 
        'تجنب معاً - استخدم ستاتين بديل آمن'),

      // ─── أدوية السكري الأخرى ───
      _create(uuid, clinicId, now, 'insulin', 'beta_blockers', 2, 
        'محصرات بيتا قد تخفي أعراض نقص السكر في الدم (خفقان ورعشة)', 
        'تثقيف المريض حول أعراض بديلة لنقص السكر (مثل التعرق الزائد)'),
      
      // ─── أدوية أخرى ───
      _create(uuid, clinicId, now, 'lisinopril', 'potassium', 3, 
        'فرط بوتاسيوم الدم الخطير، لأن ACE inhibitor يقلل إفراز البوتاسيوم', 
        'تجنب مكملات البوتاسيوم واختبر البوتاسيوم دورياً'),
    ];

    return interactions;
  }

  static Map<String, dynamic> _create(
    Uuid uuid, 
    String clinicId, 
    String time,
    String d1, 
    String d2, 
    int severity, 
    String desc, 
    String rec
  ) {
    return {
      'id': uuid.v4(),
      'clinic_id': clinicId,
      'drug1': d1.toLowerCase(),
      'drug2': d2.toLowerCase(),
      'severity': severity,
      'interaction_description': desc,
      'recommendation': rec,
      'evidence_source': 'Clinical Pharmacogenomics Seeder / RxNorm Logic',
      'is_active': 1,
      'created_at': time,
      'last_updated_at': time,
    };
  }
}
