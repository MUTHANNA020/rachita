import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/medicine_entity.dart';

abstract class MedicineRepository {
  Future<Either<Failure, List<MedicineEntity>>> searchMedicines(String query);
  Future<Either<Failure, void>> incrementUsage(int medicineId);
  Future<Either<Failure, void>> seedMedicines(List<MedicineEntity> medicines);
}
