import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rachita/core/services/sync_service.dart';
import 'package:rachita/core/services/backup_and_sync_service.dart';
import 'package:rachita/features/patient/presentation/providers/patient_provider.dart';
import 'package:rachita/features/doctor/presentation/providers/doctor_provider.dart';

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, AsyncValue<BackupStatus>>((ref) {
  return SyncStatusNotifier(ref);
});

class SyncStatusNotifier extends StateNotifier<AsyncValue<BackupStatus>> {
  final Ref ref;

  SyncStatusNotifier(this.ref)
      : super(AsyncValue.data(BackupStatus(
          isInProgress: false,
          message: 'جاهز للمزامنة',
          lastSyncTime: DateTime(2020, 1, 1),
          syncedItems: 0,
          totalItems: 0,
          progress: 0,
        )));

  Future<void> pushToServer() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(syncServiceProvider);
      await service.syncLocalToServer();
      
      state = AsyncValue.data(BackupStatus(
        isInProgress: false,
        message: 'تم رفع البيانات الجديدة بنجاح',
        lastSyncTime: DateTime.now(),
        syncedItems: 0,
        totalItems: 0,
        progress: 1,
      ));
    } catch (e) {
      state = AsyncValue.error('خطأ في رفع البيانات: $e', StackTrace.current);
    }
  }

  Future<void> pullFromServer() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(syncServiceProvider);
      final result = await service.pullServerToLocal();

      if (result.success) {
        // تحديث الواجهات
        ref.invalidate(patientsProvider);
        ref.invalidate(doctorProvider);

        state = AsyncValue.data(BackupStatus(
          isInProgress: false,
          message: '✅ ${result.message}',
          lastSyncTime: DateTime.now(),
          syncedItems: result.patientCount,
          totalItems: result.prescriptionCount,
          progress: 1,
        ));
      } else {
        state = AsyncValue.error(result.message, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error('فشل الاستيراد: $e', StackTrace.current);
    }
  }
}

class SyncAndBackupScreen extends ConsumerWidget {
  const SyncAndBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final service = ref.watch(backupSyncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المزامنة والنسخ الاحتياطي'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حالة المزامنة
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: syncStatus.when(
                    data: (status) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status.isInProgress
                                  ? Icons.sync
                                  : Icons.check_circle,
                              color: status.isInProgress
                                  ? Colors.amber
                                  : Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              status.message,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: status.progress,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'آخر مزامنة: ${status.lastSyncTime.toLocal().toString().split('.')[0]}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Column(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade400, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(color: Colors.red.shade400),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // أزرار المزامنة
              Text(
                'المزامنة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(syncStatusProvider.notifier).pushToServer();
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('رفع البيانات للسيرفر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(syncStatusProvider.notifier).pullFromServer();
                },
                icon: const Icon(Icons.cloud_download),
                label: const Text('سحب البيانات من السيرفر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }
}
