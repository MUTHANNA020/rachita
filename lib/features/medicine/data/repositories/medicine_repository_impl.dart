import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/medicine_entity.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../models/medicine_model.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  final DatabaseHelper _databaseHelper;

  MedicineRepositoryImpl(this._databaseHelper);

  @override
  Future<Either<Failure, List<MedicineEntity>>> searchMedicines(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const Right([]);
    
    // Sanitize query for FTS5 to avoid syntax errors with special chars (like ;)
    final sanitizedQuery = trimmedQuery
        .replaceAll(';', ' ')
        .replaceAll('"', ' ')
        .replaceAll("'", ' ')
        .replaceAll('*', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll('-', ' ');
    if (sanitizedQuery.trim().isEmpty) return const Right([]);
    
    try {
      final db = await _databaseHelper.database;
      
      final results = await db.rawQuery('''
        SELECT m.* FROM ${DBConstants.tableMedicines} m
        JOIN ${DBConstants.tableMedicinesFts} f ON f.rowid = m.id
        WHERE ${DBConstants.tableMedicinesFts} MATCH ?
        ORDER BY use_count DESC
        LIMIT 25
      ''', ['${sanitizedQuery.trim()}*']);      
      
      if (results.isEmpty && trimmedQuery.length > 2) {
        final fallback = await db.query(
          DBConstants.tableMedicines,
          where: 'name_ar LIKE ? OR name_en LIKE ?',
          whereArgs: ['%$trimmedQuery%', '%$trimmedQuery%'],
          orderBy: 'use_count DESC',
          limit: 15,
        );
        return Right(fallback.map((map) => MedicineModel.fromMap(map)).toList());
      }
      
      return Right(results.map((map) => MedicineModel.fromMap(map)).toList());
    } catch (e) {
      try {
        final db = await _databaseHelper.database;
        final fallback = await db.query(
          DBConstants.tableMedicines,
          where: 'name_ar LIKE ? OR name_en LIKE ?',
          whereArgs: ['%${sanitizedQuery.trim()}%', '%${sanitizedQuery.trim()}%'],
          orderBy: 'use_count DESC',
          limit: 10,
        );
        return Right(fallback.map((map) => MedicineModel.fromMap(map)).toList());
      } catch (e2) {
        return Left(DatabaseFailure('فشل في البحث عن الدواء: $e2'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> incrementUsage(int medicineId) async {
    try {
      final db = await _databaseHelper.database;
      await db.rawUpdate(
        'UPDATE ${DBConstants.tableMedicines} SET use_count = use_count + 1 WHERE id = ?',
        [medicineId],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل في تحديث الاستخدام: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> seedMedicines(List<MedicineEntity> medicines) async {
    try {
      final db = await _databaseHelper.database;
      final batch = db.batch();
      for (var medicine in medicines) {
         final model = MedicineModel.fromEntity(medicine);
         batch.insert(DBConstants.tableMedicines, model.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('فشل في إدخال الأدوية: $e'));
    }
  }
}
