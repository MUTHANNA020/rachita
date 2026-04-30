using System;
using System.Text.Json.Serialization;

namespace Rachita.Core.Entities;

public class MedicationTemplate
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// العيادة التي تملك هذا النموذج
    /// </summary>
    public Guid ClinicId { get; set; }

    /// <summary>
    /// اسم النموذج - مثال: "استنزاف أنفلونزا (بالغ)"
    /// </summary>
    public string Name { get; set; } = string.Empty!;

    /// <summary>
    /// وصف النموذج - متى يُستخدم
    /// مثال: "للحمى والعطس والسعال عند البالغين"
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// التخصص الطبي - General, Pediatrics, Cardiology, إلخ
    /// </summary>
    public string? Specialty { get; set; }

    /// <summary>
    /// قائمة الأدوية - JSON array
    /// البنية:
    /// [
    ///   {
    ///     "name": "Paracetamol",
    ///     "dosage": "500mg",
    ///     "frequency": "3x daily",
    ///     "duration": "3 days",
    ///     "indication": "Fever, Pain",
    ///     "routeOfAdministration": "Oral"
    ///   }
    /// ]
    /// </summary>
    public string MedicinesJson { get; set; } = "[]";

    /// <summary>
    /// هل النموذج نشط ومتاح للاستخدام
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// عدد مرات استخدام هذا النموذج
    /// </summary>
    public int UsageCount { get; set; } = 0;

    /// <summary>
    /// الإصدار - إذا أضفت/عدّلت النموذج
    /// </summary>
    public int Version { get; set; } = 1;

    /// <summary>
    /// متى تم إنشاء النموذج
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// آخر استخدام
    /// </summary>
    public DateTime? LastUsedAt { get; set; }

    /// <summary>
    /// آخر تحديث
    /// </summary>
    public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public Clinic? Clinic { get; set; }
}
