import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/patient_entity.dart';

abstract class PatientRepository {
  Future<Either<Failure, List<PatientEntity>>> getPatients();
  Future<Either<Failure, PatientEntity>> getPatientById(int id);
  Future<Either<Failure, PatientEntity>> insertPatient(PatientEntity patient);
  Future<Either<Failure, PatientEntity>> updatePatient(PatientEntity patient);
  Future<Either<Failure, void>> deletePatient(int id);
  Future<Either<Failure, int>> getGlobalPatientCount();
}
