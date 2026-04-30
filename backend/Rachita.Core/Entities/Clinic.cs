using System;
using System.Collections.Generic;

namespace Rachita.Core.Entities;

public class Clinic
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? ContactNumber { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string SubscriptionTier { get; set; } = "Free"; // Free, Pro, VIP
    public string Status { get; set; } = "Active"; // Active, Trial, Suspended

    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<Patient> Patients { get; set; } = new List<Patient>();
}
