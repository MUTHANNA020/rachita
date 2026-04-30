class MedicineEntity {
  final int? id;
  final String nameAr;
  final String? nameEn;
  final String? category;
  final String? commonDose;
  final String? commonFreq;
  final int useCount;
  final DateTime updatedAt;

  MedicineEntity({
    this.id,
    required this.nameAr,
    this.nameEn,
    this.category,
    this.commonDose,
    this.commonFreq,
    this.useCount = 0,
    required this.updatedAt,
  });
}
