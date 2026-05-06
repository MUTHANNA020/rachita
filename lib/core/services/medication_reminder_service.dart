import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../database/database_constants.dart';

class MedicationReminderService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> init() async {
    tz.initializeTimeZones();
    final dynamic timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timeZoneInfo is String ? timeZoneInfo : timeZoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  /// Schedule a new medication reminder
  Future<void> scheduleReminder({
    required int patientId,
    required String patientName,
    required String medicineName,
    required String time, // HH:mm
    int? prescriptionId,
  }) async {
    final db = await _dbHelper.database;
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    // 1. Save to Database
    await db.insert(DBConstants.tableMedicationReminders, {
      'id': id,
      'patient_id': patientId,
      'prescription_id': prescriptionId,
      'medicine_name': medicineName,
      'reminder_time': time,
      'is_active': 1,
      'created_at': now,
    });

    // 2. Schedule Local Notification
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final scheduledDate = _nextInstanceOfTime(hour, minute);
    
    // Hash string ID to int for notification ID
    final intNotificationId = id.hashCode.abs();

    await _notificationsPlugin.zonedSchedule(
      id: intNotificationId,
      title: 'موعد دواء: $patientName',
      body: 'حان وقت جرعة ($medicineName)',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'تذكيرات الأدوية',
          channelDescription: 'تنبيهات بمواعيد أخذ الأدوية',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Daily at this time
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Get reminders for a patient
  Future<List<Map<String, dynamic>>> getPatientReminders(int patientId) async {
    final db = await _dbHelper.database;
    return await db.query(
      DBConstants.tableMedicationReminders,
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'reminder_time ASC',
    );
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DBConstants.tableMedicationReminders,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notificationsPlugin.cancel(id: id.hashCode.abs());
  }
}

final medicationReminderServiceProvider = Provider<MedicationReminderService>((ref) {
  return MedicationReminderService();
});
