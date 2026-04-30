using System;
using System.Text.Json.Serialization;

namespace Rachita.Core.Entities;

public class VitalSign
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PrescriptionId { get; set; }
    public double? Weight { get; set; }
    public int? Systolic { get; set; }
    public int? Diastolic { get; set; }
    public int? Sugar { get; set; }
    public double? Temperature { get; set; }
    public string? ExtraVitalsJson { get; set; }
    
    public DateTime LastModifiedAt { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public Prescription? Prescription { get; set; }
}
