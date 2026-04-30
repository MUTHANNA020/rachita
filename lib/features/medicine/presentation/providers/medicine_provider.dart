import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/entities/medicine_entity.dart';

final medicineSearchProvider = FutureProvider.family<List<MedicineEntity>, String>((ref, query) async {
  if (query.length < 2) return [];
  final repo = ref.watch(medicineRepositoryProvider);
  final result = await repo.searchMedicines(query);
  return result.fold(
    (l) => [],
    (r) => r,
  );
});

final medicineNotifierProvider = Provider((ref) => MedicineActionNotifier(ref));

class MedicineActionNotifier {
  final Ref ref;
  MedicineActionNotifier(this.ref);

  Future<void> incrementUsage(int medicineId) async {
    final repo = ref.read(medicineRepositoryProvider);
    await repo.incrementUsage(medicineId);
  }
}
