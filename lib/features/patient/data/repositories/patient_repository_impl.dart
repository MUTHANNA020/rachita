import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/patient_entity.dart';
import '../../domain/repositories/patient_repository.dart';
import '../models/patient_model.dart';

class PatientRepositoryImpl implements PatientRepository {
  final DatabaseHelper _databaseHelper;

  PatientRepositoryImpl(this._databaseHelper);

  @override
  Future<Either<Failure, List<PatientEntity>>> getPatients() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBConstants.tablePatients, 
        where: 'is_deleted = 0',
        orderBy: 'updated_at DESC'
      );
      return Right(maps.map((map) => PatientModel.fromMap(map)).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المرضى: $e'));
    }
  }

  @override
  Future<Either<Failure, PatientEntity>> getPatientById(int id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(DBConstants.tablePatients, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return Right(PatientModel.fromMap(maps.first));
      } else {
        return const Left(DatabaseFailure('لم يتم العثور على المريض'));
      }
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب المريض: $e'));
    }
  }

  @override
  Future<Either<Failure, PatientEntity>> insertPatient(PatientEntity patient) async {
    try {
      final db = await _databaseHelper.database;
      
      // 1. Check for duplicate names (Case-insensitive)
      final normalizedName = patient.name.trim().toLowerCase();
      final existing = await db.query(
        DBConstants.tablePatients,
        where: 'LOWER(TRIM(name)) = ? AND is_deleted = 0',
        whereArgs: [normalizedName],
      );

      if (existing.isNotEmpty) {
        return const Left(DatabaseFailure('هذا الاسم مسجل مسبقاً لمريض آخر في العيادة.'));
      }

      final patientModel = PatientModel.fromEntity(patient);
      final id = await db.insert(DBConstants.tablePatients, patientModel.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      return Right(PatientModel.fromMap({...patientModel.toMap(), 'id': id}));
    } catch (e) {
      return Left(DatabaseFailure('فشل في إضافة المريض: $e'));
    }
  }

  @override
  Future<Either<Failure, PatientEntity>> updatePatient(PatientEntity patient) async {
    try {
      final db = await _databaseHelper.database;
      
      // 1. Check for duplicate names (Case-insensitive) if name changed
      final normalizedName = patient.name.trim().toLowerCase();
      final existing = await db.query(
        DBConstants.tablePatients,
        where: 'LOWER(TRIM(name)) = ? AND id != ? AND is_deleted = 0',
        whereArgs: [normalizedName, patient.id],
      );

      if (existing.isNotEmpty) {
        return const Left(DatabaseFailure('هذا الاسم مسجل مسبقاً لمريض آخر. لا يمكن تكرار الأسماء.'));
      }

      final patientModel = PatientModel.fromEntity(patient);
      
      final updatedMap = patientModel.toMap();
      updatedMap['updated_at'] = DateTime.now().toUtc().toIso8601String();
      updatedMap['is_synced'] = 0;

      await db.update(DBConstants.tablePatients, updatedMap, where: 'id = ?', whereArgs: [patient.id]);
      return Right(PatientModel.fromMap(updatedMap));
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث المريض: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePatient(int id) async {
    try {
      final db = await _databaseHelper.database;
      // Soft Delete: Mark as deleted and unsynced
      await db.update(
        DBConstants.tablePatients, 
        {
          'is_deleted': 1,
          'is_synced': 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, 
        where: 'id = ?', 
        whereArgs: [id]
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حذف المريض من الجهاز والسيرفر: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getGlobalPatientCount() async {
    try {
      final db = await _databaseHelper.database;
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${DBConstants.tablePatients}'));
      return Right(count ?? 0);
    } catch (e) {
      return Left(DatabaseFailure('فشل في حساب المرضى: $e'));
    }
  }
}
