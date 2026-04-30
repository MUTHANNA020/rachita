class SyncLogEntity {
  final int? id;
  final String entityType;
  final int entityId;
  final String action;
  final DateTime? syncedAt;
  final String? error;

  SyncLogEntity({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.syncedAt,
    this.error,
  });
}
