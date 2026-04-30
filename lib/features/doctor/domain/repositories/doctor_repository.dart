import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/doctor_entity.dart';

abstract class DoctorRepository {
  Future<Either<Failure, DoctorEntity>> getDoctorProfile();
  Future<Either<Failure, DoctorEntity>> saveDoctorProfile(DoctorEntity doctor);
  Future<Either<Failure, void>> resetClinicData();
}
