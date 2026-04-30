import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/entities/patient_entity.dart';

final patientsProvider = AsyncNotifierProvider<PatientsNotifier, List<PatientEntity>>(() {
  return PatientsNotifier();
});

final globalPatientCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(patientRepositoryProvider);
  final result = await repo.getGlobalPatientCount();
  return result.fold((l) => 0, (r) => r);
});

final patientByIdProvider = FutureProvider.family<PatientEntity?, int>((ref, id) async {
  final repo = ref.watch(patientRepositoryProvider);
  final result = await repo.getPatientById(id);
  return result.fold((l) => null, (r) => r);
});

class PatientsNotifier extends AsyncNotifier<List<PatientEntity>> {
  @override
  FutureOr<List<PatientEntity>> build() async {
    final repo = ref.watch(patientRepositoryProvider);
    final result = await repo.getPatients();
    return result.fold(
      (failure) => Error.throwWithStackTrace(Exception(failure.message), StackTrace.current),
      (patients) => patients,
    );
  }

  Future<String?> addPatient(PatientEntity patient) async {
    final repo = ref.read(patientRepositoryProvider);
    final result = await repo.insertPatient(patient);
    return result.fold(
      (failure) => failure.message,
      (newPatient) {
        state = AsyncData([newPatient, ...(state.value ?? [])]);
        return null;
      },
    );
  }

  Future<String?> updatePatient(PatientEntity patient) async {
    final repo = ref.read(patientRepositoryProvider);
    final result = await repo.updatePatient(patient);
    return result.fold(
      (failure) => failure.message,
      (updatedPatient) {
        if (state.value != null) {
          final updatedList = state.value!.map<PatientEntity>((p) => p.id == updatedPatient.id ? updatedPatient : p).toList();
          state = AsyncData(updatedList);
        }
        return null;
      },
    );
  }

  Future<String?> deletePatient(int id) async {
    final repo = ref.read(patientRepositoryProvider);
    final result = await repo.deletePatient(id);
    return result.fold(
      (failure) => failure.message,
      (_) {
        if (state.value != null) {
          final updatedList = state.value!.where((p) => p.id != id).toList();
          state = AsyncData(updatedList);
        }
        return null;
      },
    );
  }
}