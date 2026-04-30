import 'prescription_medicine_entity.dart';

class PrescriptionEntity {
  final int? id;
  final String? syncId; // المرجع للمزامنة
  final int patientId;
  final String diagnosis;
  final String? notes;
  final DateTime date;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PrescriptionMedicineEntity>? medicines;
  final List<String>? attachments;

  // VITALS
  final double? weight;
  final int? systolic;
  final int? diastolic;
  final int? pulse;
  final double? sugar;
  final double? temperature;
  final double? height;
  final double? headCirc;
  final String? extraVitals;
  final DateTime? followUpDate;

  PrescriptionEntity({
    this.id,
    this.syncId,
    required this.patientId,
    required this.diagnosis,
    this.notes,
    required this.date,
    this.attachments,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    this.medicines,
    this.weight,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.sugar,
    this.temperature,
    this.height,
    this.headCirc,
    this.extraVitals,
    this.followUpDate,
  });

  PrescriptionEntity copyWith({
    int? id,
    String? syncId,
    int? patientId,
    String? diagnosis,
    String? notes,
    DateTime? date,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PrescriptionMedicineEntity>? medicines,
    List<String>? attachments,
    double? weight,
    int? systolic,
    int? diastolic,
    int? pulse,
    double? sugar,
    double? temperature,
    double? height,
    double? headCirc,
    String? extraVitals,
    DateTime? followUpDate,
  }) {
    return PrescriptionEntity(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      patientId: patientId ?? this.patientId,
      diagnosis: diagnosis ?? this.diagnosis,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      attachments: attachments ?? this.attachments,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      medicines: medicines ?? this.medicines,
      weight: weight ?? this.weight,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      sugar: sugar ?? this.sugar,
      temperature: temperature ?? this.temperature,
      height: height ?? this.height,
      headCirc: headCirc ?? this.headCirc,
      extraVitals: extraVitals ?? this.extraVitals,
      followUpDate: followUpDate ?? this.followUpDate,
    );
  }
}
