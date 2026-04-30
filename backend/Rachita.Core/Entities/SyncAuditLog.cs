using System;

namespace Rachita.Core.Entities;

public class SyncAuditLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ClinicId { get; set; }
    public string EntityType { get; set; } = string.Empty; // "Patient", "Prescription"
    public Guid EntityId { get; set; }
    public string OperationType { get; set; } = string.Empty; // "Insert", "Update", "Delete"
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string? ChangedByUserId { get; set; }
}
