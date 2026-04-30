import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../../features/patient/data/repositories/patient_repository_impl.dart';
import '../../features/doctor/data/repositories/doctor_repository_impl.dart';
import '../../features/prescription/data/repositories/prescription_repository_impl.dart';
import '../../features/medicine/data/repositories/medicine_repository_impl.dart';

final databaseProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final patientRepositoryProvider = Provider((ref) {
  return PatientRepositoryImpl(ref.watch(databaseProvider));
});

final doctorRepositoryProvider = Provider((ref) {
  return DoctorRepositoryImpl(ref.watch(databaseProvider));
});

final prescriptionRepositoryProvider = Provider((ref) {
  return PrescriptionRepositoryImpl(ref.watch(databaseProvider));
});

final medicineRepositoryProvider = Provider((ref) {
  return MedicineRepositoryImpl(ref.watch(databaseProvider));
});
