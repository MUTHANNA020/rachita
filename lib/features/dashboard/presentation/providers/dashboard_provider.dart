import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

class DashboardStats {
  final int totalPatients;
  final int patientsToday;
  final int patientsYesterday;
  final int prescriptionsThisMonth;
  final List<Map<String, dynamic>> commonDiagnoses;
  final List<Map<String, dynamic>> commonMedicines;
  final List<Map<String, dynamic>> weeklyChartData;

  DashboardStats({
    required this.totalPatients,
    required this.patientsToday,
    required this.patientsYesterday,
    required this.prescriptionsThisMonth,
    required this.commonDiagnoses,
    required this.commonMedicines,
    required this.weeklyChartData,
  });

  double get patientsGrowth {
    if (patientsYesterday == 0) return patientsToday > 0 ? 100.0 : 0.0;
    return ((patientsToday - patientsYesterday) / patientsYesterday) * 100;
  }
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final dbHelper = ref.watch(databaseProvider);
  final db = await dbHelper.database;

  // 1. Total Patients
  final totalPatientsRes = await db.rawQuery("SELECT COUNT(*) as count FROM patients");
  int totalPatients = totalPatientsRes.first['count'] as int? ?? 0;

  // 2. Patients Today (based on unique patients in prescriptions)
  final todayRes = await db.rawQuery('''
    SELECT COUNT(DISTINCT patient_id) as count 
    FROM prescriptions 
    WHERE date(date) = date('now', 'localtime')
  ''');
  int patientsToday = todayRes.first['count'] as int? ?? 0;

  // 3. Patients Yesterday
  final yesterdayRes = await db.rawQuery('''
    SELECT COUNT(DISTINCT patient_id) as count 
    FROM prescriptions 
    WHERE date(date) = date('now', '-1 day', 'localtime')
  ''');
  int patientsYesterday = yesterdayRes.first['count'] as int? ?? 0;

  // 4. Prescriptions This Month
  final monthRes = await db.rawQuery('''
    SELECT COUNT(*) as count 
    FROM prescriptions 
    WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now', 'localtime')
  ''');
  int prescriptionsThisMonth = monthRes.first['count'] as int? ?? 0;

  // 5. Common Diagnoses (Top 10)
  final diagRes = await db.rawQuery('''
    SELECT diagnosis, COUNT(*) as count
    FROM prescriptions
    GROUP BY diagnosis
    ORDER BY count DESC
    LIMIT 10
  ''');

  // 6. Common Medicines (Top 10)
  final medRes = await db.rawQuery('''
    SELECT medicine_name, COUNT(*) as count
    FROM prescription_medicines
    GROUP BY medicine_name
    ORDER BY count DESC
    LIMIT 10
  ''');

  // 7. Weekly Chart Data (Last 7 days)
  final chartRes = await db.rawQuery('''
    SELECT date(date) as day, COUNT(DISTINCT patient_id) as visits
    FROM prescriptions
    WHERE date >= date('now', '-7 days', 'localtime')
    GROUP BY day
    ORDER BY day ASC
  ''');

  return DashboardStats(
    totalPatients: totalPatients,
    patientsToday: patientsToday,
    patientsYesterday: patientsYesterday,
    prescriptionsThisMonth: prescriptionsThisMonth,
    commonDiagnoses: diagRes,
    commonMedicines: medRes,
    weeklyChartData: chartRes,
  );
});
