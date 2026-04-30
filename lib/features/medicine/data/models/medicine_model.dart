import '../../domain/entities/medicine_entity.dart';

class MedicineModel extends MedicineEntity {
  MedicineModel({
    super.id,
    required super.nameAr,
    super.nameEn,
    super.category,
    super.commonDose,
    super.commonFreq,
    super.useCount,
    required super.updatedAt,
  });

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    DateTime updatedAt;
    try {
      updatedAt = (map['updated_at'] == null || map['updated_at'] == "") 
          ? DateTime.now() 
          : DateTime.parse(map['updated_at']);
    } catch (_) {
      updatedAt = DateTime.now();
    }

    return MedicineModel(
      id: map['id'],
      nameAr: map['name_ar'],
      nameEn: map['name_en'],
      category: map['category'],
      commonDose: map['common_dose'],
      commonFreq: map['common_freq'],
      useCount: map['use_count'] ?? 0,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'category': category,
      'common_dose': commonDose,
      'common_freq': commonFreq,
      'use_count': useCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MedicineModel.fromEntity(MedicineEntity entity) {
    return MedicineModel(
      id: entity.id,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      category: entity.category,
      commonDose: entity.commonDose,
      commonFreq: entity.commonFreq,
      useCount: entity.useCount,
      updatedAt: entity.updatedAt,
    );
  }
}
