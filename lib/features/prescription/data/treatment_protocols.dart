
class ProtocolMedicine {
  final String nameAr;
  final String nameEn;
  final String dosage;
  final String frequency;
  final String duration;
  final String? routeOfAdmin;
  final String? note;

  const ProtocolMedicine({
    required this.nameAr,
    required this.nameEn,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.routeOfAdmin,
    this.note,
  });
}

class TreatmentProtocol {
  final String diagnosisAr;
  final String diagnosisEn;
  final String speciality;
  final List<ProtocolMedicine> medicines;

  const TreatmentProtocol({
    required this.diagnosisAr,
    required this.diagnosisEn,
    required this.speciality,
    required this.medicines,
  });
}

class TreatmentProtocolsDB {
  static const List<TreatmentProtocol> _protocols = [
    // OPHTHALMOLOGY PROTOCOLS
    TreatmentProtocol(
      diagnosisAr: 'التهاب الملتحمة البكتيري',
      diagnosisEn: 'Bacterial Conjunctivitis',
      speciality: 'Ophthalmology',
      medicines: [
        ProtocolMedicine(
          nameAr: 'توبراكس (قطرة)',
          nameEn: 'Tobrex (Drops)',
          dosage: 'قطرة واحدة',
          frequency: '4 مرات يومياً',
          duration: '7 أيام',
          routeOfAdmin: 'Ocular',
          note: 'في العين المصابة',
        ),
      ],
    ),
    TreatmentProtocol(
      diagnosisAr: 'جفاف العين',
      diagnosisEn: 'Dry Eye Syndrome',
      speciality: 'Ophthalmology',
      medicines: [
        ProtocolMedicine(
          nameAr: 'هاي فريش (قطرة)',
          nameEn: 'Hyfresh (Drops)',
          dosage: 'قطرة واحدة',
          frequency: '4-6 مرات يومياً',
          duration: 'مستمر',
          routeOfAdmin: 'Ocular',
        ),
      ],
    ),

    // INTERNAL MEDICINE PROTOCOLS
    TreatmentProtocol(
      diagnosisAr: 'ارتفاع ضغط الدم الأساسي',
      diagnosisEn: 'Essential Hypertension',
      speciality: 'Internal Medicine',
      medicines: [
        ProtocolMedicine(
          nameAr: 'كونكور 5 ملجم',
          nameEn: 'Concor 5mg',
          dosage: '1 قرص',
          frequency: 'مرة واحدة صباحاً',
          duration: 'مستمر',
          routeOfAdmin: 'Oral',
        ),
        ProtocolMedicine(
          nameAr: 'أموفاسك 5 ملجم',
          nameEn: 'Amovasc 5mg',
          dosage: '1 قرص',
          frequency: 'مرة واحدة مساءً',
          duration: 'مستمر',
          routeOfAdmin: 'Oral',
        ),
      ],
    ),
    TreatmentProtocol(
      diagnosisAr: 'التهاب المعدة الحاد',
      diagnosisEn: 'Acute Gastritis',
      speciality: 'Internal Medicine',
      medicines: [
        ProtocolMedicine(
          nameAr: 'نكسيوم 40 ملجم',
          nameEn: 'Nexium 40mg',
          dosage: '1 قرص',
          frequency: 'مرة واحدة قبل الأكل',
          duration: '14 يوم',
          routeOfAdmin: 'Oral',
        ),
        ProtocolMedicine(
          nameAr: 'جافيسكون (شراب)',
          nameEn: 'Gaviscon (Syrup)',
          dosage: '10 مل',
          frequency: '3 مرات بعد الأكل',
          duration: '7 أيام',
          routeOfAdmin: 'Oral',
        ),
      ],
    ),

    // PEDIATRICS PROTOCOLS
    TreatmentProtocol(
      diagnosisAr: 'التهاب اللوزتين الحاد للأطفال',
      diagnosisEn: 'Acute Tonsillitis (Pediatric)',
      speciality: 'Pediatrics',
      medicines: [
        ProtocolMedicine(
          nameAr: 'أوجمنتين (شراب)',
          nameEn: 'Augmentin (Suspension)',
          dosage: 'حسب الوزن',
          frequency: 'مرتين يومياً',
          duration: '7 أيام',
          routeOfAdmin: 'Oral',
        ),
        ProtocolMedicine(
          nameAr: 'أدول (شراب)',
          nameEn: 'Adol (Suspension)',
          dosage: 'حسب الوزن',
          frequency: 'عند اللزوم',
          duration: '3 أيام',
          routeOfAdmin: 'Oral',
        ),
      ],
    ),

    // GENERAL SURGERY PROTOCOLS
    TreatmentProtocol(
      diagnosisAr: 'خياطة جرح سطحي',
      diagnosisEn: 'Surgical Wound Care',
      speciality: 'Surgery',
      medicines: [
        ProtocolMedicine(
          nameAr: 'أوجمنتين 1 جرام',
          nameEn: 'Augmentin 1g',
          dosage: '1 قرص',
          frequency: 'مرتين يومياً',
          duration: '5 أيام',
          routeOfAdmin: 'Oral',
        ),
        ProtocolMedicine(
          nameAr: 'فيوسيدين (كريم)',
          nameEn: 'Fucidin (Cream)',
          dosage: 'دهان بسيط',
          frequency: 'مرتين يومياً',
          duration: '7 أيام',
          routeOfAdmin: 'Topical',
          note: 'على مكان الجرح بعد التعقيم',
        ),
      ],
    ),
  ];

  static List<TreatmentProtocol> getBySpeciality(String speciality) {
    return _protocols.where((p) => p.speciality.toLowerCase() == speciality.toLowerCase()).toList();
  }

  static List<TreatmentProtocol> search(String query, String speciality) {
    if (query.isEmpty) return getBySpeciality(speciality);
    final q = query.toLowerCase();
    return _protocols.where((p) => 
      p.speciality.toLowerCase() == speciality.toLowerCase() && 
      (p.diagnosisAr.contains(q) || p.diagnosisEn.toLowerCase().contains(q))
    ).toList();
  }

  /// Search ALL protocols across all specialties — used by NLP voice parser.
  static List<TreatmentProtocol> searchAll(String rawText) {
    if (rawText.isEmpty) return List.of(_protocols);
    final q = rawText.toLowerCase();
    // Return any protocol where diagnosis OR any medicine name is mentioned
    return _protocols.where((p) {
      if (p.diagnosisAr.contains(q) || p.diagnosisEn.toLowerCase().contains(q)) return true;
      return p.medicines.any((m) =>
        q.contains(m.nameAr.toLowerCase()) ||
        q.contains(m.nameEn.toLowerCase()) ||
        m.nameAr.toLowerCase().contains(q) ||
        m.nameEn.toLowerCase().contains(q));
    }).toList();
  }

  /// Returns ALL medicines across all protocols as a flat list — for full dictionary scan.
  static List<ProtocolMedicine> getAllMedicines() {
    return _protocols.expand((p) => p.medicines).toList();
  }
}
