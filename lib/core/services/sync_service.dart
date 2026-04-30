import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/network/api_client.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../utils/map_utils.dart';
import '../../features/patient/data/models/patient_model.dart';
import '../../features/prescription/data/models/prescription_model.dart';
import '../../features/prescription/data/models/prescription_medicine_model.dart';
import '../../features/doctor/data/models/doctor_model.dart';

final syncServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncService(ApiClient(prefs));
});

class SyncService {
  final ApiClient apiClient;
  final Uuid _uuid = const Uuid();

  SyncService(this.apiClient);

  /// مزامنة شاملة للاتجاهين: رفع ثم سحب
  /// 🆕 Retry Queue: يُعيد المحاولة 3 مرات بـ Exponential Backoff قبل الاستسلام
  /// Push الفاشل لا يُلغي عملية Pull (مخصص للشبكات غير المستقرة)
  Future<SyncResult> runFullSync({Function(String, double)? onProgress}) async {
    // ─── خطوة 1: Push مع Retry ─────────────────────────────────────────────
    String? pushError;
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (onProgress != null) onProgress('رفع التغييرات المحلية (محاولة $attempt)...', 0.1 * attempt);
        await syncLocalToServer();
        pushError = null;
        break; // نجاح — اخرج من الحلقة
      } catch (e) {
        pushError = e.toString();
        debugPrint('⚠️ Push attempt $attempt/$maxRetries failed: $e');
        if (attempt < maxRetries) {
          // Exponential backoff: 2s, 4s, 8s
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }

    if (pushError != null) {
      debugPrint('❌ Push failed after $maxRetries retries: $pushError');
      // نكمل الـ Pull رغم فشل الـ Push — لا نترك المستخدم بدون بيانات السيرفر
    }

    // ─── خطوة 2: Pull ──────────────────────────────────────────────────────
    try {
      final pullResult = await pullServerToLocal(onProgress: onProgress);
      // إذا كان هناك خطأ Push نُضيفه للرسالة
      if (pushError != null && pullResult.success) {
        return SyncResult(
          success: true,
          message: '${pullResult.message}\n⚠️ تحذير: فشل رفع بعض التغييرات المحلية — ستُزامَن في المرة القادمة.',
          patientCount: pullResult.patientCount,
          prescriptionCount: pullResult.prescriptionCount,
        );
      }
      return pullResult;
    } catch (e) {
      debugPrint('❌ Pull Sync failed: $e');
      if (pushError != null) {
        return SyncResult(
            success: false,
            message: 'فشل الرفع والسحب معاً.\nالرفع: $pushError\nالسحب: $e');
      }
      return SyncResult(success: false, message: 'تعذر إكمال المزامنة: $e');
    }
  }

  /// وظيفة سحب البيانات (استيراد من السيرفر عند تسجيل الدخول)
  /// نظام "الدقة الفائقة": نضمن تسلسل العلاقات (مرضى -> روشتات) لضمان عدم ضياع البيانات
  Future<SyncResult> pullServerToLocal(
      {Function(String, double)? onProgress}) async {
    debugPrint(
        "🔄 Pull Sync: Starting high-precision atomic sync from server...");
    final prefs = await SharedPreferences.getInstance();

    try {
      if (onProgress != null) onProgress("جاري الاتصال بالسيرفر...", 0.1);

      final lastSyncStr =
          prefs.getString('last_sync_time') ?? '2000-01-01T00:00:00.000Z';
      final response =
          await apiClient.get('/Sync/pull?lastSyncTime=$lastSyncStr');
      debugPrint("📡 Server Response Status: ${response.statusCode}");

      if (!apiClient.isSuccess(response)) {
        debugPrint("❌ Server error: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 401) {
          return const SyncResult(
              success: false,
              message:
                  "انتهت صلاحية الجلسة. يرجى تسجيل الخروج والدخول مرة أخرى (Error 401)");
        }
        return SyncResult(
            success: false,
            message: "فشل الاتصال بالسيرفر (خطأ ${response.statusCode})");
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final doctorProfile = SafeMap.get(data, 'doctorProfile');
      final patients = (SafeMap.get(data, 'patients')) as List? ?? [];
      final prescriptions = (SafeMap.get(data, 'prescriptions')) as List? ?? [];

      debugPrint(
          "📊 Data Received -> Patients: ${patients.length}, Prescriptions: ${prescriptions.length}");

      final db = await DatabaseHelper.instance.database;

      int patientCount = 0;
      int rxCount = 0;
      final serverPatientSyncIds = <String>{};

      await db.transaction((txn) async {
        // 1. استيراد ملف الطبيب
        if (doctorProfile != null) {
          if (onProgress != null) onProgress("تحديث ملف الطبيب...", 0.2);
          await _upsertDoctor(txn, Map<String, dynamic>.from(doctorProfile));
        }

        // 2. استيراد المرضى
        for (int i = 0; i < patients.length; i++) {
          final p = patients[i];
          if (onProgress != null) {
            final pProgress = 0.2 + ((i / (patients.isNotEmpty ? patients.length : 1)) * 0.3);
            onProgress('استعادة سجلات المرضى (${i + 1}/${patients.length})...', pProgress);
          }
          await _upsertPatient(txn, Map<String, dynamic>.from(p));
          final syncId = p['id']?.toString() ?? p['Id']?.toString() ?? '';
          if (syncId.isNotEmpty) serverPatientSyncIds.add(syncId);
          patientCount++;
        }

        // 3. استيراد الوصفات
        for (int i = 0; i < prescriptions.length; i++) {
          final rx = prescriptions[i];
          if (onProgress != null) {
            final rProgress = 0.5 + ((i / (prescriptions.isNotEmpty ? prescriptions.length : 1)) * 0.4);
            onProgress("استعادة الوصفات الطبية (${i + 1}/${prescriptions.length})...", rProgress);
          }
          await _upsertPrescription(txn, Map<String, dynamic>.from(rx));
          rxCount++;
        }
      });

      // حذف المرضى المحليين الذين لم يرسلهم السيرفر (محذوفون نهائياً أو لم يعودوا متاحين)
      try {
        final localPatients = await db.query(
          DBConstants.tablePatients,
          columns: ['id', 'sync_id', 'is_synced', 'is_deleted'],
        );
        for (final local in localPatients) {
          final localSyncId = local['sync_id']?.toString() ?? '';
          final localIsSynced = local['is_synced'] == 1;
          
          if (localSyncId.isNotEmpty && !serverPatientSyncIds.contains(localSyncId)) {
            // لا نحذف البيانات التي لم تُرفع للسيرفر بعد (Pending Push)
            if (localIsSynced) {
              debugPrint('🗑️ Purging local patient not on server: $localSyncId');
              await db.delete(
                DBConstants.tablePatients,
                where: 'sync_id = ?',
                whereArgs: [localSyncId],
              );
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error during patient purge: $e');
      }

      debugPrint('📊 Patients — Server: ${patients.length}, Synced locally: $patientCount');
      debugPrint('📊 Prescriptions — Server: ${prescriptions.length}, Synced locally: $rxCount');

      // 4. تحديث وقت آخر مزامنة من السيرفر
      final serverTime = SafeMap.getString(data, 'serverTimestamp');
      if (serverTime.isNotEmpty) {
        await prefs.setString('last_sync_time', serverTime);
      } else {
        await prefs.setString(
            'last_sync_time', DateTime.now().toIso8601String());
      }

      final msg = "✅ تم بنجاح استعادة $patientCount مريض و $rxCount روشتة";
      if (onProgress != null) onProgress(msg, 1.0);

      return SyncResult(
          success: true,
          message: msg,
          patientCount: patientCount,
          prescriptionCount: rxCount);
    } catch (e) {
      debugPrint("❌ Pull Sync failed with error: $e");
      return SyncResult(
          success: false, message: "حدث خطأ غير متوقع أثناء المزامنة: $e");
    }
  }

  Future<void> _upsertDoctor(
      Transaction txn, Map<String, dynamic> sData) async {
    final model = DoctorModel.fromMap(sData);
    final localData = model.toMap();

    // Mark as synced locally
    localData['is_synced'] = 1;

    final existing = await txn.query(DBConstants.tableDoctor);
    if (existing.isEmpty) {
      localData['id'] = 1;
      await txn.insert(DBConstants.tableDoctor, localData);
    } else {
      // Only overwrite if the local profile is already synced.
      // If is_synced is 0, it means the user has local changes that haven't reached the server yet.
      final localIsSynced = (existing.first['is_synced'] == 1);
      
      if (localIsSynced) {
        final id = existing.first['id'];
        await txn.update(DBConstants.tableDoctor, localData,
            where: 'id = ?', whereArgs: [id]);
      } else {
        debugPrint("ℹ️ Skipping doctor profile Pull overwrite - local changes are pending push.");
      }
    }
  }

  Future<void> _upsertPatient(
      Transaction txn, Map<String, dynamic> sData) async {
    final model = PatientModel.fromMap(sData);
    final localData = model.toMap();
    final syncId = model.syncId;

    if (syncId == null || syncId.isEmpty) return;

    // Mark as synced locally since it's coming from the server
    localData['is_synced'] = 1;

    final existingBySyncId = await txn.query(
      DBConstants.tablePatients,
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );

    if (existingBySyncId.isEmpty) {
      await txn.insert(DBConstants.tablePatients, localData);
    } else {
      await txn.update(
        DBConstants.tablePatients,
        localData,
        where: 'sync_id = ?',
        whereArgs: [syncId],
      );
    }
  }

  Future<void> _upsertPrescription(
      Transaction txn, Map<String, dynamic> rxData) async {
    // 1. البحث عن المريض المحلي المرتبط
    final patientSyncId = SafeMap.getString(rxData, 'patientId');
    final pRecord = await txn.query(DBConstants.tablePatients,
        where: 'sync_id = ?', whereArgs: [patientSyncId]);
    if (pRecord.isEmpty) {
      debugPrint(
          "⚠️ Cannot sync prescription: Patient with sync_id $patientSyncId not found locally.");
      return;
    }
    final localPatientId = pRecord.first['id'];

    // 2. معالجة الوصفة باستخدام الـ Model
    final rxModel = PrescriptionModel.fromMap(rxData);
    final localRxData = rxModel.toMap();
    localRxData['patient_id'] = localPatientId; // ربط بالمريض المحلي
    localRxData['is_synced'] = 1;

    final rxSyncId = rxModel.syncId;
    final existing = await txn.query(DBConstants.tablePrescriptions,
        where: 'sync_id = ?', whereArgs: [rxSyncId]);
    int localRxId;

    if (existing.isEmpty) {
      localRxId = await txn.insert(DBConstants.tablePrescriptions, localRxData);
    } else {
      localRxId = existing.first['id'] as int;
      await txn.update(DBConstants.tablePrescriptions, localRxData,
          where: 'sync_id = ?', whereArgs: [rxSyncId]);
    }

    // 3. استيراد الأدوية (منطق آمن ومعزول تماماً)
    final medicines = SafeMap.get(rxData, 'medicines') as List?;
    if (medicines != null) {
      // الخطوة الأولى: مسح جميع أدوية هذه الوصفة المحددة فقط (لا غيرها)
      await txn.delete(
        DBConstants.tablePrescriptionMedicines,
        where: 'prescription_id = ?',
        whereArgs: [localRxId],
      );

      // الخطوة الثانية: إدراج الأدوية الجديدة
      // نستخدم conflictAlgorithm.replace لضمان استيعاب أي تعارضات متبقية في الـ sync_id
      for (final m in medicines) {
        final mModel = PrescriptionMedicineModel.fromMap(Map<String, dynamic>.from(m));
        final mData = mModel.toMap();
        mData['prescription_id'] = localRxId;
        mData['is_synced'] = 1;

        // REPLACE: إذا كان هناك سجل آخر بنفس sync_id (في وصفة أخرى) سيتم استبداله
        // هذا يستغل قاعدة SQLite مباشرةً ويتفادى خطأ UNIQUE Constraint نهائياً
        await txn.insert(
          DBConstants.tablePrescriptionMedicines,
          mData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    // 4. تحديث علامات حيوية مستقلة (إن وجدت في قاعدة البيانات كأعمدة)
    final vitalData = SafeMap.get(rxData, 'vitalSign');
    if (vitalData != null) {
      final v = Map<String, dynamic>.from(vitalData);
      await txn.update(
          DBConstants.tablePrescriptions,
          {
            'weight': SafeMap.getDouble(v, 'weight'),
            'systolic': SafeMap.getInt(v, 'systolic'),
            'diastolic': SafeMap.getInt(v, 'diastolic'),
            'sugar': SafeMap.getDouble(v, 'sugar'),
            'temperature': SafeMap.getDouble(v, 'temperature'),
            'extra_vitals': SafeMap.getString(v, 'extraVitalsJson'),
          },
          where: 'id = ?',
          whereArgs: [localRxId]);
    }
  }

  Future<String> _getOrAssignSyncId(
      Database db, String table, Map<String, dynamic> record) async {
    if (record['sync_id'] != null && record['sync_id'].toString().isNotEmpty) {
      return record['sync_id'].toString();
    }
    final newId = _uuid.v4();
    await db.update(table, {'sync_id': newId},
        where: 'id = ?', whereArgs: [record['id']]);
    return newId;
  }

  Future<void> syncLocalToServer() async {
    final db = await DatabaseHelper.instance.database;

    // 1. Fetch Patients
    final patientResults =
        await db.query(DBConstants.tablePatients, where: 'is_synced = 0');
    var unsyncedPatients =
        patientResults.map((m) => Map<String, dynamic>.from(m)).toList();

    for (int i = 0; i < unsyncedPatients.length; i++) {
      final syncId = await _getOrAssignSyncId(
          db, DBConstants.tablePatients, unsyncedPatients[i]);
      unsyncedPatients[i]['sync_id'] = syncId;
    }

    // 2. Fetch Prescriptions
    final rxResults =
        await db.query(DBConstants.tablePrescriptions, where: 'is_synced = 0');
    var unsyncedRxs =
        rxResults.map((m) => Map<String, dynamic>.from(m)).toList();

    List<Map<String, dynamic>> fullPrescriptions = [];
    for (var rx in unsyncedRxs) {
      final rxId = rx['id'];
      final rxSyncId =
          await _getOrAssignSyncId(db, DBConstants.tablePrescriptions, rx);
      rx['sync_id'] = rxSyncId;

      // هات الـ patient_id لمعرفة الـ sync_id للمريض الخاص بهذه الوصفة
      final pResult = await db.query(DBConstants.tablePatients,
          where: 'id = ?', whereArgs: [rx['patient_id']]);
      if (pResult.isEmpty) continue;
      // التأكد من أن المريض لديه sync_id
      String patientSyncId = pResult.first['sync_id']?.toString() ?? '';
      if (patientSyncId.isEmpty) {
        patientSyncId = await _getOrAssignSyncId(db, DBConstants.tablePatients,
            Map<String, dynamic>.from(pResult.first));
      }
      rx['patient_sync_id'] = patientSyncId;

      // Get medicines
      final medResults = await db.query(DBConstants.tablePrescriptionMedicines,
          where: 'prescription_id = ?', whereArgs: [rxId]);
      var medicines =
          medResults.map((m) => Map<String, dynamic>.from(m)).toList();

      for (int i = 0; i < medicines.length; i++) {
        final mSyncId = await _getOrAssignSyncId(
            db, DBConstants.tablePrescriptionMedicines, medicines[i]);
        medicines[i]['sync_id'] = mSyncId;
      }

      // Get vitals
      final vitalResults = await db.query(DBConstants.tableVitals,
          where: 'prescription_id = ?', whereArgs: [rxId]);
      var vitals =
          vitalResults.map((m) => Map<String, dynamic>.from(m)).toList();

      if (vitals.isNotEmpty) {
        final vSyncId =
            await _getOrAssignSyncId(db, DBConstants.tableVitals, vitals.first);
        vitals.first['sync_id'] = vSyncId;
      }

      var fullRx = Map<String, dynamic>.from(rx);
      fullRx['medicines'] = medicines;
      if (vitals.isNotEmpty) {
        fullRx['vitalSign'] = vitals.first;
      }
      fullPrescriptions.add(fullRx);
    }

    // 3. Fetch Doctor Profile (Only if unsynced)
    final List<Map<String, dynamic>> doctorProfileMaps = await db.query(
      DBConstants.tableDoctor,
      where: 'is_synced = 0',
      limit: 1,
    );

    if (unsyncedPatients.isEmpty &&
        fullPrescriptions.isEmpty &&
        doctorProfileMaps.isEmpty) {
      return;
    }

    // 4. Push to Server
    final response = await apiClient.post('/Sync/push', {
      'patients': unsyncedPatients.map((p) => _mapPatientForServer(p)).toList(),
      'prescriptions':
          fullPrescriptions.map((rx) => _mapPrescriptionForServer(rx)).toList(),
      if (doctorProfileMaps.isNotEmpty)
        'doctorProfile': _mapDoctorProfileForServer(doctorProfileMaps.first),
    });

    if (apiClient.isSuccess(response)) {
      // 5. Mark as Synced Locally
      await db.transaction((txn) async {
        for (var p in unsyncedPatients) {
          await txn.update(DBConstants.tablePatients, {'is_synced': 1},
              where: 'id = ?', whereArgs: [p['id']]);
        }
        for (var rx in unsyncedRxs) {
          await txn.update(DBConstants.tablePrescriptions, {'is_synced': 1},
              where: 'id = ?', whereArgs: [rx['id']]);
        }
        if (doctorProfileMaps.isNotEmpty) {
          await txn.update(DBConstants.tableDoctor, {'is_synced': 1},
              where: 'id = ?', whereArgs: [doctorProfileMaps.first['id']]);
        }
      });
    } else {
      final errorPrefix =
          response.statusCode == 401 ? "جلسة منتهية (401)" : "خطأ خادم";
      
      String? serverError;
      if (response.body.isNotEmpty) {
        try {
          final errorData = jsonDecode(response.body);
          serverError = errorData['error']?.toString();
        } catch (_) {
          serverError = response.body;
        }
      }
      
      throw Exception(
          "$errorPrefix: ${serverError ?? 'لا يوجد رد من السيرفر'}");
    }
  }

  Map<String, dynamic> _mapDoctorProfileForServer(Map<String, dynamic> dp) {
    return {
      'name': dp['name'] ?? 'Doctor',
      'nameEn': dp['name_en'],
      'specialty': dp['specialty'] ?? 'General',
      'specialtyEn': dp['specialty_en'],
      'subSpecialty': dp['sub_specialty'],
      'subSpecialtyEn': dp['sub_specialty_en'],
      'clinicName': dp['clinic_name'] ?? 'Clinic',
      'licenseNumber': dp['license_number'],
      'credentials': dp['credentials'],
      'credentialsEn': dp['credentials_en'],
      'address': dp['address'],
      'phone': dp['phone'],
      'workingHoursFrom': dp['working_hours_from'],
      'workingHoursTo': dp['working_hours_to'],
      'bio': dp['bio'],
      'bioEn': dp['bio_en'],
      'logoPath': dp['logo_path'],
      'signaturePath': dp['signature_path'],
      'photoPath': dp['photo_path'],
      'createdAt': dp['created_at'] ?? DateTime.now().toIso8601String(),
      'updatedAt': dp['updated_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapPatientForServer(Map<String, dynamic> p) {
    return {
      'id': p['sync_id'], // استخدام الـ UUID الآن بدلاً من الدالة المؤقتة
      'name': p['name'] ?? 'مريض',
      'gender': p['gender'] ?? 'male',
      'age': p['age'] ?? 0,
      'createdAt': p['created_at'] ?? DateTime.now().toIso8601String(),
      'phone': p['phone'],
      'lastModifiedAt': p['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
      'isDeleted': p['is_deleted'] == 1,
    };
  }

  Map<String, dynamic> _mapPrescriptionForServer(Map<String, dynamic> rx) {
    return {
      'id': rx['sync_id'],
      'patientId': rx['patient_sync_id'],
      'doctorId':
          "00000000-0000-0000-0000-000000000000", // Satisfy C# Guid Required logic. Handled by backend.
      'date': rx['date'] ?? DateTime.now().toIso8601String(),
      'diagnosis': rx['diagnosis'] ?? 'غير محدد',
      'notes': rx['notes'] ?? '',
      'lastModifiedAt': rx['updated_at'] ?? DateTime.now().toIso8601String(),
      'medicines': (rx['medicines'] as List)
          .map((m) => {
                'id': m['sync_id'],
                'medicineName': m['medicine_name'] ?? 'Unknown',
                'dosage': m['dosage'] ?? '1',
                'frequency': m['frequency'] ?? '1',
                'duration': m['duration'] ?? '1',
                'instructions': m['instructions'],
              })
          .toList(),
      'vitalSign': rx['vitalSign'] != null
          ? {
              'id': rx['vitalSign']['sync_id'], // Crucial for server-side PK tracking
              'weight': rx['vitalSign']['weight'],
              'systolic': rx['vitalSign']['systolic'],
              'diastolic': rx['vitalSign']['diastolic'],
              'sugar': rx['vitalSign']['sugar'] != null
                  ? (rx['vitalSign']['sugar'] as num).toInt()
                  : null,
              'temperature': rx['vitalSign']['temperature'],
              'extraVitalsJson': rx['vitalSign']['extra_vitals'],
            }
          : null,
    };
  }
}

/// نتيجة عملية المزامنة — تُستخدم لعرض تقرير واضح للمستخدم بعد الاستيراد
class SyncResult {
  final bool success;
  final String message;
  final int patientCount;
  final int prescriptionCount;

  const SyncResult({
    required this.success,
    required this.message,
    this.patientCount = 0,
    this.prescriptionCount = 0,
  });
}
