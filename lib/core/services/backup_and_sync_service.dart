import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../network/api_client.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../database/database_helper.dart';
import '../database/database_constants.dart';

final backupSyncServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BackupAndSyncService(ApiClient(prefs), prefs);
});

class BackupStatus {
  final bool isInProgress;
  final String message;
  final DateTime lastSyncTime;
  final int syncedItems;
  final int totalItems;
  final double progress;

  BackupStatus({
    required this.isInProgress,
    required this.message,
    required this.lastSyncTime,
    required this.syncedItems,
    required this.totalItems,
    required this.progress,
  });
}

class BackupAndSyncService {
  final ApiClient apiClient;
  final SharedPreferences prefs;
  static const uuid = Uuid();

  BackupAndSyncService(this.apiClient, this.prefs);

  /// ==========================================
  /// رفع البيانات المحلية على السيرفر
  /// ==========================================
  Future<bool> pushLocalDataToServer() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. جلب جميع البيانات غير المتزامنة
      final unsyncedPatients = await db.query(
        DBConstants.tablePatients,
        where: 'is_synced = 0',
      );

      final unsyncedPrescriptions = await db.query(
        DBConstants.tablePrescriptions,
        where: 'is_synced = 0',
      );

      if (unsyncedPatients.isEmpty && unsyncedPrescriptions.isEmpty) {
        return true;
      }

      // 2. جمع البيانات المكتملة مع العلاقات
      List<Map<String, dynamic>> fullPrescriptions = [];
      for (var rx in unsyncedPrescriptions) {
        final rxId = rx['id'];

        // جلب الأدوية
        final medicines = await db.query(
          DBConstants.tablePrescriptionMedicines,
          where: 'prescription_id = ?',
          whereArgs: [rxId],
        );

        // جلب العلامات الحيوية
        final vitals = await db.query(
          DBConstants.tableVitals,
          where: 'prescription_id = ?',
          whereArgs: [rxId],
        );

        var fullRx = Map<String, dynamic>.from(rx);
        fullRx['medicines'] = medicines;
        if (vitals.isNotEmpty) {
          fullRx['vitalSign'] = vitals.first;
        }

        fullPrescriptions.add(fullRx);
      }

      // 3. إرسال البيانات للسيرفر
      final response = await apiClient.post('/Sync/push', {
        'patients':
            unsyncedPatients.map((p) => _mapPatientForServer(p)).toList(),
        'prescriptions': fullPrescriptions
            .map((rx) => _mapPrescriptionForServer(rx))
            .toList(),
      });

      if (apiClient.isSuccess(response)) {
        // 4. تحديث حالة المزامنة محلياً
        await db.transaction((txn) async {
          for (var p in unsyncedPatients) {
            await txn.update(
              DBConstants.tablePatients,
              {'is_synced': 1},
              where: 'id = ?',
              whereArgs: [p['id']],
            );
          }
          for (var rx in unsyncedPrescriptions) {
            await txn.update(
              DBConstants.tablePrescriptions,
              {'is_synced': 1},
              where: 'id = ?',
              whereArgs: [rx['id']],
            );
          }
        });

        // 5. حفظ وقت آخر مزامنة
        final now = DateTime.now().toIso8601String();
        await prefs.setString('last_sync_time', now);
        return true;
      }
      return false;
    } catch (e) {
      print('خطأ في رفع البيانات: $e');
      return false;
    }
  }

  /// ==========================================
  /// سحب البيانات من السيرفر
  /// ==========================================
  Future<bool> pullServerDataToLocal() async {
    try {
      final lastSyncTimeStr = prefs.getString('last_sync_time');
      final lastSyncTime = lastSyncTimeStr != null
          ? DateTime.parse(lastSyncTimeStr)
          : DateTime(2020, 1, 1);

      final response = await apiClient.get(
        '/Sync/pull?lastSyncTime=${lastSyncTime.toIso8601String()}',
      );

      if (!apiClient.isSuccess(response)) return false;

      final decoded = jsonDecode(response.body);
      final db = await DatabaseHelper.instance.database;

      // معالجة المرضى
      if (decoded['patients'] != null) {
        await db.transaction((txn) async {
          for (var p in decoded['patients']) {
            final localId = p['id'].toString().hashCode; // تحويل GUID إلى int
            final existing = await txn.query(
              DBConstants.tablePatients,
              where: 'id = ?',
              whereArgs: [localId],
            );

            if (existing.isEmpty) {
              await txn.insert(DBConstants.tablePatients, {
                'id': localId,
                'name': p['name'],
                'gender': p['gender'],
                'age': p['age'],
                'phone': p['phone'],
                'identity_number': p['identityNumber'],
                'is_synced': 1,
                'created_at': p['createdAt'],
                'updated_at': p['lastModifiedAt'],
              });
            } else if (DateTime.parse(p['lastModifiedAt'].toString()).isAfter(
                DateTime.parse(existing.first['updated_at'].toString()))) {
              await txn.update(
                DBConstants.tablePatients,
                {
                  'name': p['name'],
                  'gender': p['gender'],
                  'age': p['age'],
                  'phone': p['phone'],
                  'identity_number': p['identityNumber'],
                  'updated_at': p['lastModifiedAt'],
                },
                where: 'id = ?',
                whereArgs: [localId],
              );
            }
          }
        });
      }

      // حفظ وقت المزامنة
      final serverTime = decoded['serverTimestamp'];
      await prefs.setString('last_sync_time', serverTime);
      return true;
    } catch (e) {
      print('خطأ في سحب البيانات: $e');
      return false;
    }
  }

  /// ==========================================
  /// خريطة تحويل البيانات للسيرفر
  /// ==========================================
  Map<String, dynamic> _mapPatientForServer(Map<String, dynamic> p) {
    final patientId = _intToGuid(p['id']);
    return {
      'id': patientId,
      'name': p['name'],
      'gender': p['gender'],
      'age': p['age'],
      'phone': p['phone'],
      'identityNumber': p['identity_number'],
      'lastModifiedAt': p['updated_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapPrescriptionForServer(Map<String, dynamic> rx) {
    final prescriptionId = _intToGuid(rx['id']);
    final patientId = _intToGuid(rx['patient_id']);
    final doctorId = prefs.getString('doctor_id') ?? 'clinic-doctor';

    return {
      'id': prescriptionId,
      'patientId': patientId,
      'doctorId': doctorId,
      'date': rx['date'],
      'diagnosis': rx['diagnosis'],
      'notes': rx['notes'],
      'lastModifiedAt': rx['updated_at'] ?? rx['created_at'],
      'isDeleted': rx['is_deleted'] ?? false,
      'medicines': (rx['medicines'] as List?)
              ?.map((m) => {
                    'id': _intToGuid(m['id']),
                    'medicineName': m['medicine_name'],
                    'dosage': m['dosage'],
                    'frequency': m['frequency'],
                    'duration': m['duration'],
                    'instructions': m['instructions'],
                    'lastModifiedAt':
                        m['updated_at'] ?? DateTime.now().toIso8601String(),
                  })
              .toList() ??
          [],
      'vitalSign': rx['vitalSign'] != null
          ? {
              'weight': rx['vitalSign']['weight'],
              'systolic': rx['vitalSign']['systolic'],
              'diastolic': rx['vitalSign']['diastolic'],
              'pulse': rx['vitalSign']['pulse'],
              'sugar': rx['vitalSign']['sugar'],
              'temperature': rx['vitalSign']['temperature'],
              'extraVitalsJson': rx['vitalSign']['extra_vitals'],
            }
          : null,
    };
  }

  /// ==========================================
  /// تحويل الأعداد الصحيحة إلى GUID
  /// ==========================================
  String _intToGuid(dynamic id) {
    if (id is String) return id;
    final intId = (id is int) ? id : int.parse(id.toString());
    final hex = intId.toRadixString(16).padLeft(12, '0');
    return 'rachita-00-0000-0000-$hex';
  }

  // Local file backup methods removed in favor of Server Auto-Background Sync
}
