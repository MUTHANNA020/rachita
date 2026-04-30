import 'dart:convert';
import '../../domain/entities/prescription_entity.dart';
import 'prescription_medicine_model.dart';
import '../../../../core/utils/map_utils.dart';

class PrescriptionModel extends PrescriptionEntity {
  PrescriptionModel({
    super.id,
    super.syncId,
    required super.patientId,
    required super.diagnosis,
    super.notes,
    required super.date,
    super.attachments,
    super.isSynced,
    required super.createdAt,
    required super.updatedAt,
    super.medicines,
    super.weight,
    super.systolic,
    super.diastolic,
    super.pulse,
    super.sugar,
    super.temperature,
    super.height,
    super.headCirc,
    super.extraVitals,
    super.followUpDate,
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map, {List<PrescriptionMedicineModel>? medicines}) {
    final date = SafeMap.getDateTime(map, 'date') ?? 
                 SafeMap.getDateTime(map, 'Date') ?? 
                 DateTime.now();
    final createdAt = SafeMap.getDateTime(map, 'created_at') ?? 
                      SafeMap.getDateTime(map, 'CreatedAt') ?? 
                      date;

    List<String>? attachments;
    final attachmentsRaw = SafeMap.get(map, 'attachments');
    if (attachmentsRaw != null && attachmentsRaw.toString().isNotEmpty) {
      try {
        attachments = List<String>.from(jsonDecode(attachmentsRaw.toString()));
      } catch (_) {}
    }

    // Handle ID and SyncID logic
    final idVal = SafeMap.get(map, 'id');
    int? localId;
    String? syncId;

    if (idVal is int) {
      localId = idVal;
      syncId = SafeMap.getString(map, 'sync_id');
    } else if (idVal is String) {
      syncId = idVal;
    } else {
      syncId = SafeMap.getString(map, 'sync_id');
    }

    return PrescriptionModel(
      id: localId,
      syncId: syncId,
      patientId: SafeMap.getInt(map, 'patient_id'), // Note: Usually overwritten by SyncService for local storage
      diagnosis: SafeMap.getString(map, 'diagnosis', defaultValue: 'غير محدد'),
      notes: SafeMap.getString(map, 'notes'),
      date: date,
      isSynced: (SafeMap.get(map, 'is_synced') == 1 || SafeMap.get(map, 'is_synced') == true || SafeMap.get(map, 'IsSynced') == true),
      createdAt: createdAt,
      updatedAt: SafeMap.getDateTime(map, 'updated_at') ?? 
                 SafeMap.getDateTime(map, 'LastModifiedAt') ?? 
                 createdAt,
      medicines: medicines,
      attachments: attachments,
      weight: SafeMap.getDouble(map, 'weight'),
      systolic: SafeMap.getInt(map, 'systolic'),
      diastolic: SafeMap.getInt(map, 'diastolic'),
      pulse: SafeMap.getInt(map, 'pulse'),
      sugar: SafeMap.getDouble(map, 'sugar'),
      temperature: SafeMap.getDouble(map, 'temperature'),
      height: SafeMap.getDouble(map, 'height'),
      headCirc: SafeMap.getDouble(map, 'head_circ'),
      extraVitals: SafeMap.getString(map, 'extra_vitals'),
      followUpDate: SafeMap.getDateTime(map, 'follow_up_date') ?? SafeMap.getDateTime(map, 'appointment_date'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sync_id': syncId,
      'patient_id': patientId,
      'diagnosis': diagnosis,
      'notes': notes,
      'date': date.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attachments': attachments != null ? jsonEncode(attachments) : null,
      'follow_up_date': followUpDate?.toIso8601String(),
      // Vital signs — stored directly in prescriptions table for fast access
      'weight': weight,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'sugar': sugar,
      'temperature': temperature,
      'height': height,
      'head_circ': headCirc,
      'extra_vitals': extraVitals,
    };
  }

  factory PrescriptionModel.fromEntity(PrescriptionEntity entity) {
    return PrescriptionModel(
      id: entity.id,
      syncId: entity.syncId,
      patientId: entity.patientId,
      diagnosis: entity.diagnosis,
      notes: entity.notes,
      date: entity.date,
      isSynced: entity.isSynced,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      medicines: entity.medicines,
      attachments: entity.attachments,
      weight: entity.weight,
      systolic: entity.systolic,
      diastolic: entity.diastolic,
      pulse: entity.pulse,
      sugar: entity.sugar,
      temperature: entity.temperature,
      height: entity.height,
      headCirc: entity.headCirc,
      extraVitals: entity.extraVitals,
      followUpDate: entity.followUpDate,
    );
  }
}
