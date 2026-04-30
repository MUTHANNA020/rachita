using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Rachita.Core.Entities;

public class Patient
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ClinicId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Gender { get; set; } = string.Empty;
    public int? Age { get; set; }
    public string? Phone { get; set; }
    public string? IdentityNumber { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastModifiedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;

    // 🏥 الحقول الطبية الجديدة - Medical Intelligence
    /// <summary>
    /// الحساسية الطبية - مثال: "بنسلين، مسكنات"
    /// </summary>
    public string? Allergies { get; set; }

    /// <summary>
    /// الأمراض المزمنة - مثال: "السكري، ارتفاع ضغط الدم"
    /// </summary>
    public string? ChronicDiseases { get; set; }

    /// <summary>
    /// فصيلة الدم - A+, O-, B-, إلخ
    /// </summary>
    public string? BloodGroup { get; set; }

    /// <summary>
    /// الطول بـ سنتيمتر - لحساب BMI
    /// </summary>
    public double? Height { get; set; }

    /// <summary>
    /// هل المريضة حامل - مهم لـ Dosing calculations
    /// </summary>
    public bool IsPregnant { get; set; } = false;

    /// <summary>
    /// فئة العمر - Pediatric, Adult, Geriatric
    /// </summary>
    public int AgeCategory { get; set; } = (int)PatientAgeCategory.Adult;

    /// <summary>
    /// تاريخ الأدوية السابقة - JSON array
    /// البنية: [{"drug": "name", "duration": "2021-2023", "reason": "reason"}]
    /// </summary>
    public string MedicationHistoryJson { get; set; } = "[]";

    /// <summary>
    /// الأدوية الحالية - JSON array
    /// البنية: [{"drug": "name", "dosage": "500mg", "frequency": "3x daily", "startDate": "2024-01-01"}]
    /// </summary>
    public string CurrentMedicationsJson { get; set; } = "[]";

    /// <summary>
    /// الحالات المرضية المسبقة - JSON array
    /// البنية: [{"condition": "name", "diagnosedDate": "2023-01-01", "status": "active"}]
    /// </summary>
    public string PreexistingConditionsJson { get; set; } = "[]";

    [JsonIgnore]
    public PatientRiskProfile? PatientRiskProfile { get; set; }

    [JsonIgnore]
    public Clinic? Clinic { get; set; }

    [JsonIgnore]
    public ICollection<Prescription> Prescriptions { get; set; } = new List<Prescription>();
}

/// <summary>
/// فئات العمر الطبية - للجرعات والتحذيرات المخصصة
/// </summary>
public enum PatientAgeCategory
{
    /// <summary>
    /// الأطفال (0-12 سنة) - يحتاج جرعات محسوبة بالوزن
    /// </summary>
    Pediatric = 0,

    /// <summary>
    /// المراهقون (13-17 سنة)
    /// </summary>
    Adolescent = 1,

    /// <summary>
    /// البالغون (18-64 سنة)
    /// </summary>
    Adult = 2,

    /// <summary>
    /// المسنون (65-74 سنة) - قد يحتاج جرعات أقل
    /// </summary>
    Geriatric = 3,

    /// <summary>
    /// كبار السن جداً (75+ سنة) - تحذيرات إضافية
    /// </summary>
    Elderly = 4
}
