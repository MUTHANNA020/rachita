using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Rachita.Core.Entities;

public class Prescription
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PatientId { get; set; }
    public Guid DoctorId { get; set; }
    public Guid ClinicId { get; set; }

    public DateTime Date { get; set; } = DateTime.UtcNow;
    public string Diagnosis { get; set; } = string.Empty;
    public string? Notes { get; set; }
    
    // Remote syncing flag
    public DateTime LastModifiedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;

    [JsonIgnore]
    public Patient? Patient { get; set; }
    
    [JsonIgnore]
    public User? Doctor { get; set; }
    
    public VitalSign? VitalSign { get; set; }
    public ICollection<PrescriptionMedicine> PrescriptionMedicines { get; set; } = new List<PrescriptionMedicine>();
}
