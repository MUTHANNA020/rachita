class VitalsEntity {
  final int? id;
  final int patientId;
  final int? prescriptionId;
  final double? weight;
  final int? systolic;
  final int? diastolic;
  final int? pulse;
  final double? sugar;
  final double? temperature;
  final DateTime date;
  final int isSynced;
  final DateTime createdAt;

  VitalsEntity({
    this.id,
    required this.patientId,
    this.prescriptionId,
    this.weight,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.sugar,
    this.temperature,
    required this.date,
    this.isSynced = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'prescription_id': prescriptionId,
      'weight': weight,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'sugar': sugar,
      'temperature': temperature,
      'date': date.toIso8601String(),
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VitalsEntity.fromMap(Map<String, dynamic> map) {
    return VitalsEntity(
      id: map['id'],
      patientId: map['patient_id'],
      prescriptionId: map['prescription_id'],
      weight: map['weight']?.toDouble(),
      systolic: map['systolic'],
      diastolic: map['diastolic'],
      pulse: map['pulse'],
      sugar: map['sugar']?.toDouble(),
      temperature: map['temperature']?.toDouble(),
      date: DateTime.parse(map['date']),
      isSynced: map['is_synced'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  VitalsEntity copyWith({
    int? id,
    int? patientId,
    int? prescriptionId,
    double? weight,
    int? systolic,
    int? diastolic,
    int? pulse,
    double? sugar,
    double? temperature,
    DateTime? date,
    int? isSynced,
    DateTime? createdAt,
  }) {
    return VitalsEntity(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      weight: weight ?? this.weight,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      sugar: sugar ?? this.sugar,
      temperature: temperature ?? this.temperature,
      date: date ?? this.date,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
