import '../../domain/entities/patient_entity.dart';
import '../../../../core/utils/map_utils.dart';

class PatientModel extends PatientEntity {
  PatientModel({
    super.id,
    super.syncId,
    required super.name,
    super.age,
    super.gender,
    super.phone,
    super.notes,
    super.bloodGroup,
    super.height,
    super.allergies,
    super.chronicDiseases,
    super.visitCount,
    super.lastVisit,
    super.isSynced,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
    // 🏥 الحقول الجديدة
    super.isPregnant,
    super.ageCategory,
    super.medicationHistoryJson,
    super.currentMedicationsJson,
    super.preexistingConditionsJson,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    final createdAt = SafeMap.getDateTime(map, 'created_at') ??
        SafeMap.getDateTime(map, 'CreatedAt') ??
        DateTime.now();

    // Handle ID and SyncID logic
    final idVal = SafeMap.get(map, 'id');
    int? localId;
    String? syncId;

    if (idVal is int) {
      localId = idVal;
      syncId = SafeMap.getString(map, 'sync_id');
    } else if (idVal is String) {
      syncId = idVal;
      // If it's a GUID string, localId remains null for insertion or we fetch it later
    } else {
      syncId = SafeMap.getString(map, 'sync_id');
    }

    return PatientModel(
      id: localId,
      syncId: syncId,
      name: SafeMap.getString(map, 'name', defaultValue: 'مريض غير مسمى'),
      age: SafeMap.getInt(map, 'age'),
      gender: SafeMap.getString(map, 'gender'),
      phone: SafeMap.getString(map, 'phone'),
      notes: SafeMap.getString(map, 'notes'),
      bloodGroup: SafeMap.getString(map, 'blood_group') ??
          SafeMap.getString(map, 'BloodGroup'),
      height:
          SafeMap.getDouble(map, 'height') ?? SafeMap.getDouble(map, 'Height'),
      allergies: SafeMap.getString(map, 'allergies') ??
          SafeMap.getString(map, 'Allergies'),
      chronicDiseases: SafeMap.getString(map, 'chronic_diseases') ??
          SafeMap.getString(map, 'ChronicDiseases'),
      visitCount: SafeMap.getInt(map, 'visit_count'),
      lastVisit: SafeMap.getDateTime(map, 'last_visit'),
      isSynced: (SafeMap.get(map, 'is_synced') == 1 ||
          SafeMap.get(map, 'is_synced') == true ||
          SafeMap.get(map, 'IsSynced') == true),
      createdAt: createdAt,
      updatedAt: SafeMap.getDateTime(map, 'updated_at') ??
          SafeMap.getDateTime(map, 'LastModifiedAt') ??
          createdAt,
      isDeleted: (SafeMap.get(map, 'is_deleted') == 1 ||
          SafeMap.get(map, 'is_deleted') == true ||
          SafeMap.get(map, 'IsDeleted') == true),
      // 🏥 الحقول الطبية الجديدة
      isPregnant: (SafeMap.get(map, 'is_pregnant') == 1 ||
          SafeMap.get(map, 'is_pregnant') == true ||
          SafeMap.get(map, 'IsPregnant') == true),
      ageCategory: SafeMap.getInt(map, 'age_category') ??
          SafeMap.getInt(map, 'AgeCategory') ??
          2,
      medicationHistoryJson:
          SafeMap.getString(map, 'medication_history_json') ??
              SafeMap.getString(map, 'MedicationHistoryJson') ??
              '[]',
      currentMedicationsJson:
          SafeMap.getString(map, 'current_medications_json') ??
              SafeMap.getString(map, 'CurrentMedicationsJson') ??
              '[]',
      preexistingConditionsJson:
          SafeMap.getString(map, 'preexisting_conditions_json') ??
              SafeMap.getString(map, 'PreexistingConditionsJson') ??
              '[]',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sync_id': syncId,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'notes': notes,
      'blood_group': bloodGroup,
      'height': height,
      'allergies': allergies,
      'chronic_diseases': chronicDiseases,
      'visit_count': visitCount,
      'last_visit': lastVisit?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      // 🏥 الحقول الجديدة
      'is_pregnant': isPregnant ? 1 : 0,
      'age_category': ageCategory,
      'medication_history_json': medicationHistoryJson,
      'current_medications_json': currentMedicationsJson,
      'preexisting_conditions_json': preexistingConditionsJson,
    };
  }

  factory PatientModel.fromEntity(PatientEntity entity) {
    return PatientModel(
      id: entity.id,
      syncId: entity.syncId,
      name: entity.name,
      age: entity.age,
      gender: entity.gender,
      phone: entity.phone,
      notes: entity.notes,
      bloodGroup: entity.bloodGroup,
      height: entity.height,
      allergies: entity.allergies,
      chronicDiseases: entity.chronicDiseases,
      visitCount: entity.visitCount,
      lastVisit: entity.lastVisit,
      isSynced: entity.isSynced,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
      // 🏥 الحقول الجديدة
      isPregnant: entity.isPregnant,
      ageCategory: entity.ageCategory,
      medicationHistoryJson: entity.medicationHistoryJson,
      currentMedicationsJson: entity.currentMedicationsJson,
      preexistingConditionsJson: entity.preexistingConditionsJson,
    );
  }
}
