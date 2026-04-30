import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../data/doctor_patterns_repository.dart';
import '../../domain/hybrid_suggestion_engine.dart';

final doctorPatternsRepositoryProvider = Provider<DoctorPatternsRepository>((ref) {
  final dbHelper = ref.watch(databaseProvider);
  return DoctorPatternsRepository(dbHelper);
});

// Note: hybridSuggestionEngineProvider has been moved to medical_intelligence_providers.dart
// to centralize clinical intelligence logic.


final learnedSuggestionsCountProvider = FutureProvider.family<int, String>((ref, diagnosis) async {
  final repo = ref.watch(doctorPatternsRepositoryProvider);
  final results = await repo.getLearnedSuggestions(diagnosis);
  return results.length;
});

final patientPrescriptionsProvider =
    FutureProvider.family<List<PrescriptionEntity>, int>(
        (ref, patientId) async {
  final repo = ref.watch(prescriptionRepositoryProvider);
  final result = await repo.getPrescriptionsByPatientId(patientId);
  return result.fold(
    (l) => throw l.message,
    (r) => r,
  );
});

final currentPrescriptionProvider =
    StateProvider<PrescriptionEntity?>((ref) => null);

class PrescriptionActionNotifier {
  final Ref ref;
  PrescriptionActionNotifier(this.ref);

  Future<PrescriptionEntity> savePrescription(
      PrescriptionEntity prescription) async {
    final repo = ref.read(prescriptionRepositoryProvider);
    final result = await repo.savePrescription(prescription);
    
    return result.fold(
      (l) => throw l.message,
      (r) async {
        ref.read(doctorPatternsRepositoryProvider).recordPatterns(r).catchError((e) => null);
        ref.read(currentPrescriptionProvider.notifier).state = r;
        ref.invalidate(patientPrescriptionsProvider(r.patientId));
        ref.invalidate(globalPrescriptionCountProvider);
        return r;
      },
    );
  }
}

final prescriptionActionProvider =
    Provider((ref) => PrescriptionActionNotifier(ref));

final diagnosesSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(prescriptionRepositoryProvider);
  final result = await repo.getDistinctDiagnoses();
  return result.fold((l) => [], (r) => r);
});

final notesSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(prescriptionRepositoryProvider);
  final result = await repo.getDistinctNotes();
  return result.fold((l) => [], (r) => r);
});

final globalPrescriptionCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(prescriptionRepositoryProvider);
  final result = await repo.getGlobalPrescriptionCount();
  return result.fold((l) => 0, (r) => r);
});
