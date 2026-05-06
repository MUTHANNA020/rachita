import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../database/database_constants.dart';

class AuditService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Log a new action
  Future<void> logAction({
    required String action,
    String? userId,
    String? entityType,
    String? entityId,
    String? details,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(DBConstants.tableAuditLog, {
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'ip_address': ipAddress,
      'device_info': deviceInfo,
      'created_at': now,
    });
  }

  /// Get all logs (for administration)
  Future<List<Map<String, dynamic>>> getLogs({int limit = 100}) async {
    final db = await _dbHelper.database;
    return await db.query(
      DBConstants.tableAuditLog,
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }
}

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService();
});
