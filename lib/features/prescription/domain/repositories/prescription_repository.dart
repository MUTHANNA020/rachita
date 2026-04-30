import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/prescription_entity.dart';

abstract class PrescriptionRepository {
  Future<Either<Failure, List<PrescriptionEntity>>> getPrescriptionsByPatientId(int patientId);
  Future<Either<Failure, PrescriptionEntity>> getPrescriptionById(int id);
  Future<Either<Failure, PrescriptionEntity>> savePrescription(PrescriptionEntity prescription);
  Future<Either<Failure, void>> deletePrescription(int id);
  Future<Either<Failure, List<String>>> getDistinctDiagnoses();
  Future<Either<Failure, List<String>>> getDistinctNotes();
  Future<Either<Failure, int>> getGlobalPrescriptionCount();
}
