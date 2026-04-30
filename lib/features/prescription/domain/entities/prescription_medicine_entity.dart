class PrescriptionMedicineEntity {
  final int? id;
  final String? syncId; // المرجع للمزامنة
  final int? prescriptionId;
  final String medicineName;
  final String? medicineNameEn;
  final String dosage;
  final String frequency;
  final String duration;
  final String? routeOfAdmin;
  final int? totalUnits;
  final String? instructions;
  final String? dosageUnit;
  final String? frequencyDetailed;
  final String? durationUnit;
  final DateTime updatedAt;

  PrescriptionMedicineEntity({
    this.id,
    this.syncId,
    this.prescriptionId,
    required this.medicineName,
    this.medicineNameEn,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.routeOfAdmin,
    this.totalUnits,
    this.instructions,
    this.dosageUnit,
    this.frequencyDetailed,
    this.durationUnit,
    required this.updatedAt,
  });
  PrescriptionMedicineEntity copyWith({
    int? id,
    String? syncId,
    int? prescriptionId,
    String? medicineName,
    String? medicineNameEn,
    String? dosage,
    String? frequency,
    String? duration,
    String? routeOfAdmin,
    int? totalUnits,
    String? instructions,
    String? dosageUnit,
    String? frequencyDetailed,
    String? durationUnit,
    DateTime? updatedAt,
  }) {
    return PrescriptionMedicineEntity(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicineName: medicineName ?? this.medicineName,
      medicineNameEn: medicineNameEn ?? this.medicineNameEn,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      routeOfAdmin: routeOfAdmin ?? this.routeOfAdmin,
      totalUnits: totalUnits ?? this.totalUnits,
      instructions: instructions ?? this.instructions,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      frequencyDetailed: frequencyDetailed ?? this.frequencyDetailed,
      durationUnit: durationUnit ?? this.durationUnit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
