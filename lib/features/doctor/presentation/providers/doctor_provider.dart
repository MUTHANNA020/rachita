import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/entities/doctor_entity.dart';

final doctorProvider = AsyncNotifierProvider<DoctorNotifier, DoctorEntity?>(() {
  return DoctorNotifier();
});

class DoctorNotifier extends AsyncNotifier<DoctorEntity?> {
  @override
  FutureOr<DoctorEntity?> build() async {
    final repo = ref.watch(doctorRepositoryProvider);
    final result = await repo.getDoctorProfile();
    return result.fold(
      (failure) => null,
      (doctor) => doctor,
    );
  }

  Future<void> saveProfile(DoctorEntity doctor) async {
    final repo = ref.watch(doctorRepositoryProvider);
    final result = await repo.saveDoctorProfile(doctor);
    result.fold(
      (failure) => throw failure.message,
      (saved) {
        state = AsyncData(saved);
      },
    );
  }

  Future<void> resetApp() async {
    final repo = ref.watch(doctorRepositoryProvider);
    await repo.resetClinicData();
    state = const AsyncData(null);
  }
}
