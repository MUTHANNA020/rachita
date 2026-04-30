import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../models/doctor_model.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DatabaseHelper _databaseHelper;

  DoctorRepositoryImpl(this._databaseHelper);

  @override
  Future<Either<Failure, DoctorEntity>> getDoctorProfile() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(DBConstants.tableDoctor, limit: 1);
      if (maps.isNotEmpty) {
        return Right(DoctorModel.fromMap(maps.first));
      } else {
        return const Left(DatabaseFailure('لم يتم إعداد الملف الشخصي للطبيب بعد'));
      }
    } catch (e) {
      return Left(DatabaseFailure('فشل في جلب الملف الشخصي: $e'));
    }
  }

  @override
  Future<Either<Failure, DoctorEntity>> saveDoctorProfile(DoctorEntity doctor) async {
    try {
      final db = await _databaseHelper.database;
      final doctorModel = DoctorModel.fromEntity(doctor);
      
      final updatedMap = doctorModel.toMap();
      updatedMap['updated_at'] = DateTime.now().toIso8601String();
      updatedMap['is_synced'] = 0; // Mark as needs sync

      final existing = await db.query(DBConstants.tableDoctor, limit: 1);
      final logoLen = (doctor.logoPath?.length ?? 0);
      final photoLen = (doctor.photoPath?.length ?? 0);
      print("💾 Saving Doctor Profile: Logo Size: $logoLen bytes, Photo Size: $photoLen bytes");

      if (existing.isEmpty) {
         updatedMap['id'] = 1;
         await db.insert(DBConstants.tableDoctor, updatedMap);
         return Right(DoctorModel.fromMap(updatedMap));
      } else {
         final id = existing.first['id'] as int;
         await db.update(DBConstants.tableDoctor, updatedMap, where: 'id = ?', whereArgs: [id]);
         final result = Map<String, dynamic>.from(updatedMap);
         result['id'] = id;
         return Right(DoctorModel.fromMap(result));
      }
    } catch (e) {
      return Left(DatabaseFailure('فشل في حفظ الملف الشخصي: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetClinicData() async {
    try {
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        await txn.delete(DBConstants.tablePatients);
        await txn.delete(DBConstants.tablePrescriptions);
        await txn.delete(DBConstants.tablePrescriptionMedicines);
        await txn.delete(DBConstants.tableDoctor);
        await txn.delete(DBConstants.tableSyncLog);
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل في تصفير البيانات: $e'));
    }
  }
}
