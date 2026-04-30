import '../../domain/entities/prescription_medicine_entity.dart';
import '../../../../core/utils/map_utils.dart';

class PrescriptionMedicineModel extends PrescriptionMedicineEntity {
  PrescriptionMedicineModel({
    super.id,
    super.syncId,
    super.prescriptionId,
    required super.medicineName,
    super.medicineNameEn,
    required super.dosage,
    required super.frequency,
    required super.duration,
    super.routeOfAdmin,
    super.totalUnits,
    super.instructions,
    super.dosageUnit,
    super.frequencyDetailed,
    super.durationUnit,
    required super.updatedAt,
  });

  factory PrescriptionMedicineModel.fromMap(Map<String, dynamic> map) {
    // Handle ID and SyncID — server sends GUID string, local DB sends int
    final idVal = SafeMap.get(map, 'id');
    int? localId;
    String? syncId;

    if (idVal is int) {
      localId = idVal;
      syncId = SafeMap.getString(map, 'sync_id');
    } else if (idVal is String && idVal.isNotEmpty) {
      syncId = idVal;  // Server GUID becomes local sync_id
    } else {
      syncId = SafeMap.getString(map, 'sync_id');
    }

    // Medicine name: server sends 'medicineName', local DB stores 'medicine_name'
    final medicineName = SafeMap.getString(map, 'medicine_name').isNotEmpty
        ? SafeMap.getString(map, 'medicine_name')
        : SafeMap.getString(map, 'medicineName', defaultValue: 'دواء غير مسمى');

    // Dosage / frequency / duration: same dual-key lookup
    final dosage = SafeMap.getString(map, 'dosage').isNotEmpty
        ? SafeMap.getString(map, 'dosage')
        : SafeMap.getString(map, 'Dosage', defaultValue: '');

    final frequency = SafeMap.getString(map, 'frequency').isNotEmpty
        ? SafeMap.getString(map, 'frequency')
        : SafeMap.getString(map, 'Frequency', defaultValue: '');

    final duration = SafeMap.getString(map, 'duration').isNotEmpty
        ? SafeMap.getString(map, 'duration')
        : SafeMap.getString(map, 'Duration', defaultValue: '');

    return PrescriptionMedicineModel(
      id: localId,
      syncId: syncId,
      prescriptionId: SafeMap.getInt(map, 'prescription_id'),
      medicineName: medicineName,
      medicineNameEn: SafeMap.getString(map, 'medicine_name_en'),
      dosage: dosage,
      frequency: frequency,
      duration: duration,
      routeOfAdmin: SafeMap.getString(map, 'route_of_admin'),
      totalUnits: SafeMap.getInt(map, 'total_units'),
      instructions: SafeMap.getString(map, 'instructions')
                    .isNotEmpty ? SafeMap.getString(map, 'instructions')
                    : SafeMap.getString(map, 'Instructions'),
      dosageUnit: SafeMap.getString(map, 'dosage_unit'),
      frequencyDetailed: SafeMap.getString(map, 'frequency_detailed'),
      durationUnit: SafeMap.getString(map, 'duration_unit'),
      updatedAt: SafeMap.getDateTime(map, 'updated_at') ??
                 SafeMap.getDateTime(map, 'lastModifiedAt') ??
                 SafeMap.getDateTime(map, 'LastModifiedAt') ??
                 DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sync_id': syncId,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      'medicine_name': medicineName,
      'medicine_name_en': medicineNameEn,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'route_of_admin': routeOfAdmin,
      'total_units': totalUnits,
      'instructions': instructions,
      'dosage_unit': dosageUnit,
      'frequency_detailed': frequencyDetailed,
      'duration_unit': durationUnit,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PrescriptionMedicineModel.fromEntity(
      PrescriptionMedicineEntity entity) {
    return PrescriptionMedicineModel(
      id: entity.id,
      syncId: entity.syncId,
      prescriptionId: entity.prescriptionId,
      medicineName: entity.medicineName,
      medicineNameEn: entity.medicineNameEn,
      dosage: entity.dosage,
      frequency: entity.frequency,
      duration: entity.duration,
      routeOfAdmin: entity.routeOfAdmin,
      totalUnits: entity.totalUnits,
      instructions: entity.instructions,
      dosageUnit: entity.dosageUnit,
      frequencyDetailed: entity.frequencyDetailed,
      durationUnit: entity.durationUnit,
      updatedAt: entity.updatedAt,
    );
  }
}
