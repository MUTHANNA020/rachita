class PatientEntity {
  final int? id;
  final String? syncId; // المرجع للمزامنة مع السيرفر
  final String name;
  final int? age;
  final String? gender;
  final String? phone;
  final String? notes;
  final String? bloodGroup;
  final double? height;
  final String? allergies;
  final String? chronicDiseases;
  final int visitCount;
  final DateTime? lastVisit;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  // 🏥 الحقول الطبية الجديدة
  /// هل المريضة حامل
  final bool isPregnant;

  /// فئة العمر - 0: Pediatric, 1: Adolescent, 2: Adult, 3: Geriatric, 4: Elderly
  final int ageCategory;

  /// تاريخ الأدوية السابقة - JSON list
  final String medicationHistoryJson;

  /// الأدوية الحالية - JSON list
  final String currentMedicationsJson;

  /// الحالات المرضية المسبقة - JSON list
  final String preexistingConditionsJson;

  PatientEntity({
    this.id,
    this.syncId,
    required this.name,
    this.age,
    this.gender,
    this.phone,
    this.notes,
    this.bloodGroup,
    this.height,
    this.allergies,
    this.chronicDiseases,
    this.visitCount = 0,
    this.lastVisit,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    // 🏥 الجديدة
    this.isPregnant = false,
    this.ageCategory = 2, // Adult by default
    this.medicationHistoryJson = '[]',
    this.currentMedicationsJson = '[]',
    this.preexistingConditionsJson = '[]',
  });
}
