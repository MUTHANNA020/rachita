/// Medical Speech Normalizer
/// Corrects common speech-to-text misrecognitions for pharmaceutical terms.
/// Uses: direct lookup → phonetic correction → Levenshtein fuzzy match.
class MedicalSpeechNormalizer {
  // ─── Master drug dictionary (speech variant → canonical name) ─────────────
  static const Map<String, String> _dict = {
    // ── Antibiotics ──────────────────────────────────────────────────────────
    'amoxicillin': 'Amoxicillin',
    'amoxicilin': 'Amoxicillin',
    'amoxisylin': 'Amoxicillin',
    'amoxycillin': 'Amoxicillin',
    'amoxil': 'Amoxicillin',
    'augmentin': 'Augmentin',
    'augmentan': 'Augmentin',
    'coamoxiclav': 'Augmentin',
    'co-amoxiclav': 'Augmentin',
    'azithromycin': 'Azithromycin',
    'azythromycin': 'Azithromycin',
    'zithromax': 'Azithromycin',
    'azithro': 'Azithromycin',
    'ciprofloxacin': 'Ciprofloxacin',
    'ciprofloaxicin': 'Ciprofloxacin',
    'ciprofloxasin': 'Ciprofloxacin',
    'cipro': 'Ciprofloxacin',
    'ciproxin': 'Ciprofloxacin',
    'clarithromycin': 'Clarithromycin',
    'clarythromycin': 'Clarithromycin',
    'klacid': 'Clarithromycin',
    'doxycycline': 'Doxycycline',
    'doxycicline': 'Doxycycline',
    'metronidazole': 'Metronidazole',
    'metronidazol': 'Metronidazole',
    'flagyl': 'Metronidazole',
    'penicillin': 'Penicillin',
    'penicilin': 'Penicillin',
    'cephalexin': 'Cephalexin',
    'cefuroxime': 'Cefuroxime',
    'ceftriaxone': 'Ceftriaxone',
    'clindamycin': 'Clindamycin',
    'levofloxacin': 'Levofloxacin',
    'moxifloxacin': 'Moxifloxacin',
    'trimethoprim': 'Trimethoprim',
    'sulfamethoxazole': 'Sulfamethoxazole',
    'bactrim': 'Trimethoprim/Sulfamethoxazole',
    'vancomycin': 'Vancomycin',
    'erythromycin': 'Erythromycin',
    'nitrofurantoin': 'Nitrofurantoin',

    // ── Pain / Anti-inflammatory ──────────────────────────────────────────────
    'ibuprofen': 'Ibuprofen',
    'iboprofen': 'Ibuprofen',
    'ibooprofen': 'Ibuprofen',
    'brufen': 'Ibuprofen',
    'advil': 'Ibuprofen',
    'motrin': 'Ibuprofen',
    'paracetamol': 'Paracetamol',
    'paracetamole': 'Paracetamol',
    'acetaminophen': 'Paracetamol',
    'panadol': 'Paracetamol',
    'tylenol': 'Paracetamol',
    'diclofenac': 'Diclofenac',
    'diclofenac sodium': 'Diclofenac',
    'voltaren': 'Diclofenac',
    'voltarol': 'Diclofenac',
    'naproxen': 'Naproxen',
    'aleve': 'Naproxen',
    'aspirin': 'Aspirin',
    'asparine': 'Aspirin',
    'celecoxib': 'Celecoxib',
    'celebrex': 'Celecoxib',
    'meloxicam': 'Meloxicam',
    'tramadol': 'Tramadol',
    'tramadole': 'Tramadol',
    'codeine': 'Codeine',
    'morphine': 'Morphine',
    'pregabalin': 'Pregabalin',
    'lyrica': 'Pregabalin',
    'gabapentin': 'Gabapentin',
    'neurontin': 'Gabapentin',

    // ── Blood Pressure ────────────────────────────────────────────────────────
    'lisinopril': 'Lisinopril',
    'lisinipril': 'Lisinopril',
    'amlodipine': 'Amlodipine',
    'amlopidine': 'Amlodipine',
    'norvasc': 'Amlodipine',
    'atenolol': 'Atenolol',
    'atenolole': 'Atenolol',
    'metoprolol': 'Metoprolol',
    'metoprolole': 'Metoprolol',
    'losartan': 'Losartan',
    'losarton': 'Losartan',
    'cozaar': 'Losartan',
    'valsartan': 'Valsartan',
    'diovan': 'Valsartan',
    'ramipril': 'Ramipril',
    'bisoprolol': 'Bisoprolol',
    'carvedilol': 'Carvedilol',
    'furosemide': 'Furosemide',
    'lasix': 'Furosemide',
    'hydrochlorothiazide': 'Hydrochlorothiazide',
    'spironolactone': 'Spironolactone',
    'aldactone': 'Spironolactone',
    'nifedipine': 'Nifedipine',
    'diltiazem': 'Diltiazem',
    'verapamil': 'Verapamil',

    // ── Diabetes ──────────────────────────────────────────────────────────────
    'metformin': 'Metformin',
    'glucophage': 'Metformin',
    'glibenclamide': 'Glibenclamide',
    'glyburide': 'Glibenclamide',
    'glipizide': 'Glipizide',
    'gliclazide': 'Gliclazide',
    'diamicron': 'Gliclazide',
    'sitagliptin': 'Sitagliptin',
    'sitagliptan': 'Sitagliptin',
    'januvia': 'Sitagliptin',
    'empagliflozin': 'Empagliflozin',
    'jardiance': 'Empagliflozin',
    'dapagliflozin': 'Dapagliflozin',
    'farxiga': 'Dapagliflozin',
    'forxiga': 'Dapagliflozin',
    'linagliptin': 'Linagliptin',
    'trajenta': 'Linagliptin',
    'insulin': 'Insulin',
    'glargine': 'Insulin Glargine',
    'lantus': 'Insulin Glargine',
    'novolog': 'Insulin Aspart',
    'humalog': 'Insulin Lispro',

    // ── GI / Stomach ──────────────────────────────────────────────────────────
    'omeprazole': 'Omeprazole',
    'omeprazol': 'Omeprazole',
    'losec': 'Omeprazole',
    'prilosec': 'Omeprazole',
    'pantoprazole': 'Pantoprazole',
    'pantoprazol': 'Pantoprazole',
    'protonix': 'Pantoprazole',
    'esomeprazole': 'Esomeprazole',
    'nexium': 'Esomeprazole',
    'rabeprazole': 'Rabeprazole',
    'ranitidine': 'Ranitidine',
    'zantac': 'Ranitidine',
    'famotidine': 'Famotidine',
    'pepcid': 'Famotidine',
    'domperidone': 'Domperidone',
    'motilium': 'Domperidone',
    'metoclopramide': 'Metoclopramide',
    'maxolon': 'Metoclopramide',
    'ondansetron': 'Ondansetron',
    'zofran': 'Ondansetron',
    'hyoscine': 'Hyoscine',
    'buscopan': 'Hyoscine',

    // ── Allergy / Respiratory ─────────────────────────────────────────────────
    'cetirizine': 'Cetirizine',
    'cetrizine': 'Cetirizine',
    'zyrtec': 'Cetirizine',
    'loratadine': 'Loratadine',
    'claritin': 'Loratadine',
    'fexofenadine': 'Fexofenadine',
    'allegra': 'Fexofenadine',
    'chlorpheniramine': 'Chlorpheniramine',
    'montelukast': 'Montelukast',
    'singulair': 'Montelukast',
    'salbutamol': 'Salbutamol',
    'albuterol': 'Salbutamol',
    'ventolin': 'Salbutamol',
    'formoterol': 'Formoterol',
    'salmeterol': 'Salmeterol',
    'fluticasone': 'Fluticasone',
    'budesonide': 'Budesonide',
    'symbicort': 'Budesonide/Formoterol',
    'seretide': 'Fluticasone/Salmeterol',
    'amoxiclavulanic': 'Augmentin',
    'augmenten': 'Augmentin',
    'amoxiclav': 'Augmentin',
    'coamoxid': 'Augmentin',
    'flu': 'Influenza',
    'cold': 'Common Cold',
    'cough': 'Cough',
    'headache': 'Headache',
    'pain': 'Pain',
    'fever': 'Fever',
    'shortness of breath': 'Dyspnea',
    'dyspnea': 'Dyspnea',
    'asthma': 'Asthma',
    'astha': 'Asthma',
    'bronchitis': 'Bronchitis',
    'pneumonia': 'Pneumonia',

    // ── Cholesterol ───────────────────────────────────────────────────────────
    'atorvastatin': 'Atorvastatin',
    'lipitor': 'Atorvastatin',
    'simvastatin': 'Simvastatin',
    'zocor': 'Simvastatin',
    'rosuvastatin': 'Rosuvastatin',
    'crestor': 'Rosuvastatin',
    'pravastatin': 'Pravastatin',
    'ezetimibe': 'Ezetimibe',
    'zetia': 'Ezetimibe',

    // ── Thyroid ───────────────────────────────────────────────────────────────
    'levothyroxine': 'Levothyroxine',
    'synthroid': 'Levothyroxine',
    'thyroxine': 'Levothyroxine',

    // ── Vitamins & Supplements ────────────────────────────────────────────────
    'vitamin d': 'Vitamin D',
    'vitamin c': 'Vitamin C',
    'vitamin b12': 'Vitamin B12',
    'folic acid': 'Folic Acid',
    'folate': 'Folic Acid',
    'iron': 'Iron',
    'ferrous sulfate': 'Ferrous Sulfate',
    'calcium': 'Calcium',
    'zinc': 'Zinc',
    'omega 3': 'Omega-3',
    'omega-3': 'Omega-3',

    // ── Dermatology ───────────────────────────────────────────────────────────
    'hydrocortisone': 'Hydrocortisone',
    'betamethasone': 'Betamethasone',
    'clotrimazole': 'Clotrimazole',
    'canesten': 'Clotrimazole',
    'fluconazole': 'Fluconazole',
    'diflucan': 'Fluconazole',
    'ketoconazole': 'Ketoconazole',
    'nizoral': 'Ketoconazole',
    'mupirocin': 'Mupirocin',
    'bactroban': 'Mupirocin',
    'acyclovir': 'Acyclovir',
    'zovirax': 'Acyclovir',
    'tretinoin': 'Tretinoin',
    'retin-a': 'Tretinoin',

    // ── Neurology / Psychiatry ────────────────────────────────────────────────
    'sertraline': 'Sertraline',
    'zoloft': 'Sertraline',
    'fluoxetine': 'Fluoxetine',
    'prozac': 'Fluoxetine',
    'amitriptyline': 'Amitriptyline',
    'diazepam': 'Diazepam',
    'valium': 'Diazepam',
    'alprazolam': 'Alprazolam',
    'xanax': 'Alprazolam',
    'risperidone': 'Risperidone',
    'haloperidol': 'Haloperidol',

    // ── Ophthalmology ────────────────────────────────────────────────────────
    'timolol': 'Timolol',
    'latanoprost': 'Latanoprost',
    'xalatan': 'Latanoprost',
    'dorzolamide': 'Dorzolamide',
    'trusopt': 'Dorzolamide',
    'gentamicin': 'Gentamicin',
    'tobramycin': 'Tobramycin',
    'dexamethasone': 'Dexamethasone',
    'prednisolone': 'Prednisolone',

    // ── Arabic Common Drug Names ──────────────────────────────────────────────
    'اموكسيسيلين': 'Amoxicillin',
    'أموكسيسيلين': 'Amoxicillin',
    'اموكسيل': 'Amoxicillin',
    'اوزمنتن': 'Augmentin',
    'أوجمنتين': 'Augmentin',
    'ازيثروميسين': 'Azithromycin',
    'أزيثروميسين': 'Azithromycin',
    'سيبروفلوكساسين': 'Ciprofloxacin',
    'سيبروفلوكسين': 'Ciprofloxacin',
    'سيبرو': 'Ciprofloxacin',
    'ميترونيدازول': 'Metronidazole',
    'فلاجيل': 'Metronidazole',
    'باراسيتامول': 'Paracetamol',
    'بنادول': 'Paracetamol',
    'ايبوبروفين': 'Ibuprofen',
    'ايبوبرفين': 'Ibuprofen',
    'برفين': 'Ibuprofen',
    'ديكلوفيناك': 'Diclofenac',
    'فولتارين': 'Diclofenac',
    'اوميبرازول': 'Omeprazole',
    'أوميبرازول': 'Omeprazole',
    'اوميبرازل': 'Omeprazole',
    'بانتوبرازول': 'Pantoprazole',
    'ميتفورمين': 'Metformin',
    'جلوكوفاج': 'Metformin',
    'اتورفاستاتين': 'Atorvastatin',
    'ليبيتور': 'Atorvastatin',
    'لوساتان': 'Losartan',
    'لوزارتان': 'Losartan',
    'السيتريزين': 'Cetirizine',
    'سيتريزين': 'Cetirizine',
    'زيرتك': 'Cetirizine',
    'لوراتادين': 'Loratadine',
    'كلاريتين': 'Loratadine',
    'مونتيلوكاست': 'Montelukast',
    'سنجولير': 'Montelukast',
    'سالبوتامول': 'Salbutamol',
    'فنتولين': 'Salbutamol',
    'فنتولن': 'Salbutamol',
    'ليفوثيروكسين': 'Levothyroxine',
    'ثيروكسين': 'Levothyroxine',
    'فلوكونازول': 'Fluconazole',
    'ديفلوكان': 'Fluconazole',
    'سيرترالين': 'Sertraline',
    'زولوفت': 'Sertraline',
    'ديازيبام': 'Diazepam',
    'فاليوم': 'Diazepam',
    'بريدنيزولون': 'Prednisolone',
    'ديكساميثازون': 'Dexamethasone',
    'جنتاميسين': 'Gentamicin',
    'حمض الفوليك': 'Folic Acid',
    'فيتامين د': 'Vitamin D',
    'فيتامين سي': 'Vitamin C',
    'كالسيوم': 'Calcium',
    'زنك': 'Zinc',
    'ضغط الدم': 'Blood Pressure',
    'ارتفاع الضغط': 'Hypertension',
    'مرض السكر': 'Diabetes mellitus',
    'السكري': 'Diabetes',
    'الم في الصدر': 'Chest Pain',
    'ضيق تنفس': 'Shortness of breath',
    'حراره': 'Fever',
    'كحه': 'Cough',
    'سعال': 'Cough',
    'صداع': 'Headache',
    'غثيان': 'Nausea',
    'اقياء': 'Vomiting',
    'استفراغ': 'Vomiting',
    'امساك': 'Constipation',
    'اسهال': 'Diarrhea',
    'التهاب': 'Inflammation',
    'عدوى': 'Infection',
    'مضاد حيوي': 'Antibiotic',
    'مسكن': 'Analgesic',
    'مرهم': 'Ointment',
    'قطره': 'Drops',
    'شراب': 'Syrup',
    'حبوب': 'Tablets',
    'كبسولات': 'Capsules',
    'حقنه': 'Injection',
    'مره واحده': 'Once daily',
    'مرتين': 'Twice daily',
    'ثلاث مرات': 'Three times daily',
    'اربع مرات': 'Four times daily',
    'كل ست ساعات': 'Every 6 hours',
    'كل ثمان ساعات': 'Every 8 hours',
    'كل ١٢ ساعه': 'Every 12 hours',
    'before نوم': 'At bedtime',
    'at bedtime': 'At bedtime',

    // ── Common Misrecognitions ────────────────────────────────────────────────
    'information': 'Inflammation',
    'inform': 'Inflammation',
    'inflamation': 'Inflammation',
    'enflamation': 'Inflammation',
    'infection': 'Infection',
    'infectin': 'Infection',
    'infaction': 'Infection',
    'syrup': 'Syrup',
    'serup': 'Syrup',
    'tablet': 'Tablets',
    'tablets': 'Tablets',
    'capsule': 'Capsules',
    'capsules': 'Capsules',
    'injection': 'Injection',
    'inject': 'Injection',
    'ointment': 'Ointment',
    'cream': 'Ointment/Cream',
  };

  /// Normalizes a full dictated phrase, correcting each pharmaceutical term.
  static String normalize(String rawText) {
    if (rawText.trim().isEmpty) return rawText;

    // 1. Check if the entire phrase matches a known drug mapping
    final fullLower = rawText.trim().toLowerCase();
    if (_dict.containsKey(fullLower)) return _dict[fullLower]!;

    // 2. Word-by-word correction
    final words = rawText.trim().split(RegExp(r'\s+'));
    final corrected = <String>[];

    int i = 0;
    while (i < words.length) {
      // Try 3-word then 2-word then single-word lookup
      bool matched = false;
      for (final len in [3, 2, 1]) {
        if (i + len > words.length) continue;
        final phrase = words.sublist(i, i + len).join(' ').toLowerCase();
        if (_dict.containsKey(phrase)) {
          corrected.add(_dict[phrase]!);
          i += len;
          matched = true;
          break;
        }
      }
      if (!matched) {
        // Try fuzzy match for single word
        final word = words[i];
        final fuzzy = _fuzzyMatch(word.toLowerCase());
        corrected.add(fuzzy ?? _capitalize(word));
        i++;
      }
    }

    String result = corrected.join(' ');
    result = _normalizeDosageAndFrequency(result);
    return result;
  }

  /// Advanced processing for standardizing doses, routes, and frequencies.
  static String _normalizeDosageAndFrequency(String text) {
    String t = text;
    // Common dosages
    t = t.replaceAll(RegExp(r'\b(milli\s*grams?|milligrams?)\b', caseSensitive: false), 'mg');
    t = t.replaceAll(RegExp(r'\b(grams?)\b', caseSensitive: false), 'g');
    t = t.replaceAll(RegExp(r'\b(micro\s*grams?|micrograms?)\b', caseSensitive: false), 'mcg');
    t = t.replaceAll(RegExp(r'\b(milli\s*liters?|milliliters?|ml)\b', caseSensitive: false), 'mL');
    
    // Spacing around doses (e.g., '500 mg' -> '500mg')
    t = t.replaceAllMapped(RegExp(r'(\d+)\s+(mg|g|mcg|mL)\b', caseSensitive: false), (match) => '${match[1]}${match[2]}');

    // Frequency & Instructions
    final frequencyMap = {
      r'\b(once a day|once daily|one time a day)\b': 'OD',
      r'\b(twice a day|twice daily|two times a day)\b': 'BID',
      r'\b(three times a day|three times daily)\b': 'TID',
      r'\b(four times a day|four times daily)\b': 'QID',
      r'\b(every day|daily)\b': 'Daily',
      r'\b(as needed|when required)\b': 'PRN',
      r'\b(every other day)\b': 'EOD',
      r'\b(before meals?|before eating)\b': 'AC',
      r'\b(after meals?|after eating)\b': 'PC',
      r'\b(by mouth|orally)\b': 'PO',
      r'\b(at bedtime|at night)\b': 'HS',
    };

    frequencyMap.forEach((pattern, replacement) {
      t = t.replaceAll(RegExp(pattern, caseSensitive: false), replacement);
    });

    // Arabic equivalents
    final arabicFreqMap = {
      r'\b(مره\s*باليوم|مرة\s*في\s*اليوم|مرة\s*باليوم|مره\s*واحده|مرة\s*واحدة|حبة\s*باليوم)\b': 'مرة يومياً (OD)',
      r'\b(مرتين\s*باليوم|مرتين\s*في\s*اليوم|صباحا\s*ومساء|صباحاً\s*ومساءً|حبتين\s*باليوم)\b': 'مرتين يومياً (BID)',
      r'\b(ثلاث\s*مرات|ثلاث\s*مرات\s*باليوم|٣\s*مرات|ثلاث\s*مرات\s*في\s*اليوم)\b': '٣ مرات يومياً (TID)',
      r'\b(عند\s*الحاجه|عند\s*اللزوم|وقت\s*الحاجه|عند\s*الضرورة)\b': 'عند اللزوم (PRN)',
      r'\b(قبل\s*الاكل|قبل\s*الطعام|قبل\s*الوجبه|قبل\s*الوجبة)\b': 'قبل الأكل (AC)',
      r'\b(بعد\s*الاكل|بعد\s*الطعام|بعد\s*الوجبه|بعد\s*الوجبة)\b': 'بعد الأكل (PC)',
      r'\b(ملي\s*غرام|ملليغرام|ملغم|ملج)\b': 'mg',
      r'\b(غرام|جرام|جم)\b': 'g',
      r'\b(ملي|مل)\b': 'mL',
    };

    arabicFreqMap.forEach((pattern, replacement) {
      t = t.replaceAll(RegExp(pattern, caseSensitive: false), replacement);
    });

    return t;
  }

  /// Returns the best fuzzy match from the dictionary or null if below threshold.
  static String? _fuzzyMatch(String word) {
    if (word.length < 4) return null;

    String? bestKey;
    int bestDist = 999;

    for (final key in _dict.keys) {
      // Only compare keys that start with the same letter or are phonetically similar
      if (key.isEmpty || (key[0] != word[0] && !_phoneticallyClose(key[0], word[0]))) {
        continue;
      }
      final dist = _levenshtein(word, key);
      // Adaptive threshold: allow 1–3 edits based on word length
      final threshold = word.length <= 6 ? 1 : word.length <= 10 ? 2 : 3;
      if (dist < bestDist && dist <= threshold) {
        bestDist = dist;
        bestKey = key;
      }
    }

    return bestKey != null ? _dict[bestKey] : null;
  }

  static bool _phoneticallyClose(String a, String b) {
    const groups = [
      {'f', 'v', 'ph'},
      {'c', 'k', 'q', 'x'},
      {'s', 'z', 'sh', 'c'},
      {'i', 'e', 'y', 'a'},
      {'o', 'u', 'w'},
      {'j', 'g', 'ch'},
      {'t', 'd'},
      {'b', 'p'}, // Very important for Arabic speakers
    ];
    for (final g in groups) {
      if (g.contains(a) && g.contains(b)) return true;
    }
    return false;
  }

  /// Specialized similarity check that favors clinical matches.
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    final dist = _levenshtein(s1, s2);
    final maxLen = s1.length > s2.length ? s1.length : s2.length;
    if (maxLen == 0) return 1.0;
    return 1.0 - (dist / maxLen);
  }

  /// Capitalize first letter of a word.
  static String _capitalize(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }

  /// Classic Levenshtein distance (edit distance).
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List.generate(t.length + 1, (i) => i);
    final v1 = List.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      v0.setAll(0, v1);
    }

    return v0[t.length];
  }

  /// Checks if a word looks like a known pharmaceutical term (for UI hints).
  static bool isKnownDrug(String word) {
    final lower = word.toLowerCase().trim();
    return _dict.containsKey(lower) || _fuzzyMatch(lower) != null;
  }

  /// Parses the raw text to detect Copilot UI commands.
  static VoiceCommandResult parseIntent(String rawText) {
    final t = rawText.toLowerCase().trim();

    if (t.contains('احفظ الروشتة') || t.contains('حفظ الروشتة') || t.contains('save prescription')) {
      return VoiceCommandResult(intent: VoiceIntent.save);
    }
    if (t.contains('اطبع الروشتة') || t.contains('طباعة') || t.contains('print prescription')) {
      return VoiceCommandResult(intent: VoiceIntent.print);
    }
    if (t.contains('امسح') || t.contains('مسح الكل') || t.contains('clear all')) {
      return VoiceCommandResult(intent: VoiceIntent.clear);
    }
    if (t.contains('مريض جديد') || t.contains('المريض التالي') || t.contains('next patient')) {
      return VoiceCommandResult(intent: VoiceIntent.nextPatient);
    }
    if (t.contains('صرف') || t.contains('بروتوكول') || t.contains('علاج')) {
      // Possible trigger for proactive suggestions
      return VoiceCommandResult(intent: VoiceIntent.suggestProtocol, cleanedText: normalize(t));
    }

    return VoiceCommandResult(intent: VoiceIntent.dictation, cleanedText: normalize(t));
  }

  /// NEW: High-Precision Structured Medicine Parsing
  /// Extracts [Drug Name, Dosage, Frequency, Duration] from a clinical string.
  static ParsedMedicine parseMedicineCommand(String rawText) {
    final normalized = normalize(rawText);
    
    // 1. Extract Dosage (e.g., 500mg, 10ml, 1g)
    final doseMatch = RegExp(r'(\d+(\.\d+)?\s*(mg|g|mcg|mL|units|iu|حبة|كبسولة|مل))', caseSensitive: false).firstMatch(normalized);
    String dosage = doseMatch?.group(0) ?? '';
    
    // 2. Extract Duration (e.g., 5 days, 1 week, لمدة أسبوع)
    final durMatch = RegExp(r'(\d+\s*(days|weeks|months|أيام|اسبوع|شهر|يوم))', caseSensitive: false).firstMatch(normalized);
    String duration = durMatch?.group(0) ?? '';

    // 3. Extract Frequency (Look for acronyms or Arabic standard phrases)
    final frequencies = ['OD', 'BID', 'TID', 'QID', 'PRN', 'Daily', 'HS', 'مرة يومياً', 'مرتين يومياً', '٣ مرات يومياً', 'قبل الأكل', 'بعد الأكل'];
    String frequency = '';
    for (final f in frequencies) {
      if (normalized.contains(f)) {
        frequency = f;
        break;
      }
    }

    // 4. Extract Medicine Name (Assuming it's at the beginning or before dosage)
    String name = normalized;
    if (dosage.isNotEmpty) {
      name = name.split(dosage)[0].trim();
    }
    
    // Final cleanup of name: look for the first 3 words max or first match in dict
    final words = name.split(' ');
    if (words.length > 3) {
      name = words.sublist(0, 3).join(' ');
    }

    return ParsedMedicine(
      name: name.isNotEmpty ? name : rawText.trim(),
      dosage: dosage,
      dosageUnit: doseMatch?.group(3) ?? '',
      frequency: frequency,
      duration: duration,
      rawNormalized: normalized,
    );
  }

  /// NEW MASSIVE UPGRADE: Multi-Intent Parsing
  /// Extracts MULTIPLE medicines from a single continuous audio stream.
  /// Example: "اصرف بنادول حبتين في اليوم وبروفين 400 ملغ عند اللزوم"
  static List<ParsedMedicine> extractMultipleMedicines(String rawText) {
    final normalized = normalize(rawText);
    final results = <ParsedMedicine>[];
    
    // 1. Identify all known drugs in the sentence using sliding window
    final words = normalized.split(RegExp(r'\s+'));
    final drugIndices = <int, String>{}; 
    
    for (int i = 0; i < words.length; i++) {
       // Skip very small words
       if (words[i].length < 3) continue;

       // try 2 words (e.g. "vitamin d")
       if (i < words.length - 1) {
          final phrase = '${words[i]} ${words[i+1]}';
          if (isKnownDrug(phrase)) {
             drugIndices[i] = _dict[phrase.toLowerCase()] ?? _capitalize(phrase);
             i++; 
             continue;
          }
       }
       // try single word
       if (isKnownDrug(words[i])) {
          final fuzzy = _fuzzyMatch(words[i].toLowerCase());
          drugIndices[i] = fuzzy ?? _capitalize(words[i]);
       }
    }
    
    // If we didn't find any known drugs, fallback to single parse
    if (drugIndices.isEmpty) {
        final single = parseMedicineCommand(rawText);
        if (single.name.trim().isNotEmpty && single.name.length > 2) {
           return [single];
        }
        return [];
    }

    // Segment the text based on drug indices
    final indices = drugIndices.keys.toList()..sort();
    
    for (int i = 0; i < indices.length; i++) {
        final startIndex = indices[i];
        final endIndex = (i < indices.length - 1) ? indices[i+1] : words.length;
        
        final chunk = words.sublist(startIndex, endIndex).join(' ');
        final parsed = parseMedicineCommand(chunk);
        
        results.add(ParsedMedicine(
            name: drugIndices[startIndex]!,
            dosage: parsed.dosage,
            dosageUnit: parsed.dosageUnit,
            frequency: parsed.frequency,
            duration: parsed.duration,
            rawNormalized: chunk,
        ));
    }

    return results;
  }
}

class ParsedMedicine {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String dosageUnit;
  final String route;
  final String rawNormalized;

  ParsedMedicine({
    required this.name,
    this.dosage = '',
    this.dosageUnit = '',
    this.frequency = '',
    this.duration = '',
    this.route = '',
    required this.rawNormalized,
  });

  @override
  String toString() => 'Med: $name | Dose: $dosage | Freq: $frequency | Dur: $duration';
}

enum VoiceIntent {
  dictation,
  save,
  print,
  clear,
  nextPatient,
  suggestProtocol,
}

class VoiceCommandResult {
  final VoiceIntent intent;
  final String cleanedText;
  
  VoiceCommandResult({required this.intent, this.cleanedText = ''});
}
