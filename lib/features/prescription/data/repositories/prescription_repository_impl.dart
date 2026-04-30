import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../models/prescription_model.dart';
import '../models/prescription_medicine_model.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final DatabaseHelper _databaseHelper;

  PrescriptionRepositoryImpl(this._databaseHelper);

  @override
  Future<Either<Failure, List<PrescriptionEntity>>> getPrescriptionsByPatientId(int patientId) async {
    try {
      final db = await _databaseHelper.database;
      final prescriptionMaps = await db.query(DBConstants.tablePrescriptions, where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'date DESC');
      
      if (prescriptionMaps.isEmpty) return const Right([]);

      final ids = prescriptionMaps.map((m) => m['id'] as int).toList();
      
      // OPTIMIZATION: Bulk load all medicines for these prescriptions in ONE query
      final allMedsMaps = await db.query(
        DBConstants.tablePrescriptionMedicines, 
        where: 'prescription_id IN (${ids.map((_) => '?').join(',')})',
        whereArgs: ids,
      );
      
      Map<int, List<PrescriptionMedicineModel>> medsMap = {};
      for (var m in allMedsMaps) {
        final rxId = m['prescription_id'] as int;
        medsMap.putIfAbsent(rxId, () => []).add(PrescriptionMedicineModel.fromMap(m));
      }

      // OPTIMIZATION: Bulk load all vitals for these prescriptions in ONE query
      final allVitalsMaps = await db.query(
        DBConstants.tableVitals,
        where: 'prescription_id IN (${ids.map((_) => '?').join(',')})',
        whereArgs: ids,
      );
      
      Map<int, Map<String, dynamic>> vitalsByRx = {};
      for (var v in allVitalsMaps) {
        final rxId = v['prescription_id'] as int;
        vitalsByRx[rxId] = Map<String, dynamic>.from(v);
      }

      List<PrescriptionEntity> prescriptions = [];
      for (var map in prescriptionMaps) {
        final rxId = map['id'] as int;
        
        Map<String, dynamic> combinedMap = Map.from(map);
        if (vitalsByRx.containsKey(rxId)) {
          final vitals = vitalsByRx[rxId]!;
          vitals.remove('id');
          vitals.remove('patient_id');
          vitals.remove('prescription_id');
          vitals.remove('date');
          vitals.remove('created_at');
          combinedMap.addAll(vitals);
        }
        
        prescriptions.add(PrescriptionModel.fromMap(combinedMap, medicines: medsMap[rxId]));
      }
      return Right(prescriptions);
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الوصفات الطبية: $e'));
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> getPrescriptionById(int id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(DBConstants.tablePrescriptions, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        final medsMaps = await db.query(DBConstants.tablePrescriptionMedicines, where: 'prescription_id = ?', whereArgs: [id]);
        final meds = medsMaps.map((m) => PrescriptionMedicineModel.fromMap(m)).toList();
        
        // Load vitals
        final vitalsMaps = await db.query(DBConstants.tableVitals, where: 'prescription_id = ?', whereArgs: [id]);
        Map<String, dynamic> combinedMap = Map.from(maps.first);
        if (vitalsMaps.isNotEmpty) {
          final vitals = Map<String, dynamic>.from(vitalsMaps.first);
          vitals.remove('id'); // Don't overwrite prescription ID
          vitals.remove('patient_id');
          vitals.remove('prescription_id');
          vitals.remove('date');
          vitals.remove('created_at');
          combinedMap.addAll(vitals);
        }

        return Right(PrescriptionModel.fromMap(combinedMap, medicines: meds));
      } else {
        return const Left(DatabaseFailure('لم يتم العثور على الوصفة'));
      }
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الوصفة: $e'));
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> savePrescription(PrescriptionEntity prescription) async {
    try {
      final db = await _databaseHelper.database;
      final prescriptionModel = PrescriptionModel.fromEntity(prescription);
      
      int id = prescriptionModel.id ?? 0;
      final nowStr = DateTime.now().toIso8601String();
      
      await db.transaction((txn) async {
        if (prescriptionModel.id == null) {
          final insertMap = prescriptionModel.toMap();
          insertMap['updated_at'] = nowStr;
          id = await txn.insert(DBConstants.tablePrescriptions, insertMap);
        } else {
          final updatedMap = prescriptionModel.toMap();
          updatedMap['is_synced'] = 0;
          updatedMap['updated_at'] = nowStr;
          await txn.update(DBConstants.tablePrescriptions, updatedMap, where: 'id = ?', whereArgs: [id]);
          await txn.delete(DBConstants.tablePrescriptionMedicines, where: 'prescription_id = ?', whereArgs: [id]);
          await txn.delete(DBConstants.tableVitals, where: 'prescription_id = ?', whereArgs: [id]);
        }
        
        // Save medicines
        if (prescription.medicines != null) {
          for (var med in prescription.medicines!) {
            final medModel = PrescriptionMedicineModel.fromEntity(med);
            final medMap = medModel.toMap();
            medMap['prescription_id'] = id;
            await txn.insert(DBConstants.tablePrescriptionMedicines, medMap);
          }
        }

        // Save vitals
        if (prescription.weight != null || prescription.systolic != null || prescription.sugar != null || prescription.pulse != null || prescription.extraVitals != null) {
          await txn.insert(DBConstants.tableVitals, {
            'patient_id': prescription.patientId,
            'prescription_id': id,
            'weight': prescription.weight,
            'systolic': prescription.systolic,
            'diastolic': prescription.diastolic,
            'pulse': prescription.pulse,
            'sugar': prescription.sugar,
            'temperature': prescription.temperature,
            'extra_vitals': prescription.extraVitals,
            'date': prescription.date.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      });
      
      return getPrescriptionById(id);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حفظ الوصفة: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePrescription(int id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(DBConstants.tablePrescriptions, where: 'id = ?', whereArgs: [id]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف الوصفة: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getDistinctDiagnoses() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('SELECT DISTINCT diagnosis FROM ${DBConstants.tablePrescriptions} WHERE diagnosis IS NOT NULL AND diagnosis != "" ORDER BY diagnosis ASC');
      return Right(result.map((row) => row['diagnosis'] as String).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب التشخيصات: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getDistinctNotes() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('SELECT DISTINCT notes FROM ${DBConstants.tablePrescriptions} WHERE notes IS NOT NULL AND notes != "" ORDER BY notes ASC');
      return Right(result.map((row) => row['notes'] as String).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الملاحظات: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getGlobalPrescriptionCount() async {
    try {
      final db = await _databaseHelper.database;
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${DBConstants.tablePrescriptions}'));
      return Right(count ?? 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حساب الوصفات: $e'));
    }
  }
}
