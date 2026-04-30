import 'package:rachita/features/prescription/domain/entities/prescription_entity.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';

class DoctorPattern {
  final String diagnosis;
  final String medicineName;
  final String? medicineNameEn;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? routeOfAdmin;
  final int useCount;
  final DateTime lastUsed;

  DoctorPattern({
    required this.diagnosis,
    required this.medicineName,
    this.medicineNameEn,
    this.dosage,
    this.frequency,
    this.duration,
    this.routeOfAdmin,
    required this.useCount,
    required this.lastUsed,
  });

  Map<String, dynamic> toMap() {
    return {
      'diagnosis': diagnosis,
      'medicine_name': medicineName,
      'medicine_name_en': medicineNameEn,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'route_of_admin': routeOfAdmin,
      'use_count': useCount,
      'last_used': lastUsed.toIso8601String(),
    };
  }

  factory DoctorPattern.fromMap(Map<String, dynamic> map) {
    return DoctorPattern(
      diagnosis: map['diagnosis'] ?? '',
      medicineName: map['medicine_name'] ?? '',
      medicineNameEn: map['medicine_name_en'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      duration: map['duration'],
      routeOfAdmin: map['route_of_admin'],
      useCount: map['use_count'] ?? 1,
      lastUsed: DateTime.parse(map['last_used']),
    );
  }
}

class DoctorPatternsRepository {
  final DatabaseHelper _dbHelper;

  DoctorPatternsRepository(this._dbHelper);

  Future<void> recordPatterns(PrescriptionEntity prescription) async {
    final db = await _dbHelper.database;
    final diagnosis = prescription.diagnosis.trim();
    if (diagnosis.isEmpty) return;

    for (var med in prescription.medicines ?? []) {
      final medName = med.medicineName.trim();
      if (medName.isEmpty) continue;

      await db.transaction((txn) async {
        await txn.rawInsert('''
          INSERT INTO ${DBConstants.tableDoctorPatterns} 
          (diagnosis, medicine_name, medicine_name_en, dosage, frequency, duration, route_of_admin, use_count, last_used)
          VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
          ON CONFLICT(diagnosis, medicine_name) DO UPDATE SET
            use_count = use_count + 1,
            last_used = excluded.last_used,
            dosage = excluded.dosage,
            frequency = excluded.frequency,
            duration = excluded.duration,
            route_of_admin = excluded.route_of_admin
        ''', [
          diagnosis,
          medName,
          med.medicineNameEn,
          med.dosage,
          med.frequency,
          med.duration,
          med.routeOfAdmin,
          DateTime.now().toIso8601String(),
        ]);
      });
    }
  }

  Future<List<DoctorPattern>> getLearnedSuggestions(String diagnosis, {int limit = 5}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DBConstants.tableDoctorPatterns,
      where: 'diagnosis = ?',
      whereArgs: [diagnosis.trim()],
      orderBy: 'use_count DESC',
      limit: limit,
    );

    return results.map((m) => DoctorPattern.fromMap(m)).toList();
  }
}
