using System;

namespace Rachita.Core.Entities;

public class DoctorProfile
{
    public int Id { get; set; } = 1; // It can just be 1 since it's 1-to-1 with Clinic mostly, but let's use a Guid for distributed systems.
    public Guid ClinicId { get; set; }
    
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string Specialty { get; set; } = string.Empty;
    public string? SpecialtyEn { get; set; }
    public string? SubSpecialty { get; set; }
    public string? SubSpecialtyEn { get; set; }
    public string ClinicName { get; set; } = string.Empty;
    public string? LicenseNumber { get; set; }
    public string? Credentials { get; set; }
    public string? CredentialsEn { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? WorkingHoursFrom { get; set; }
    public string? WorkingHoursTo { get; set; }
    public string? LogoPath { get; set; }
    public string? SignaturePath { get; set; }
    public string? PhotoPath { get; set; }
    public string? Bio { get; set; }
    public string? BioEn { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Clinic? Clinic { get; set; }
}
