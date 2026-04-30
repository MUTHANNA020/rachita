using System;
using System.Text.Json.Serialization;

namespace Rachita.Core.Entities;

public class PrescriptionMedicine
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PrescriptionId { get; set; }
    public string MedicineName { get; set; } = string.Empty;
    public string Dosage { get; set; } = string.Empty;
    public string Frequency { get; set; } = string.Empty;
    public string Duration { get; set; } = string.Empty;
    public string? Instructions { get; set; }

    // 🏥 الحقول الطبية الجديدة
    /// <summary>
    /// طريقة الإعطاء - Oral, Intramuscular, Intravenous, Topical, إلخ
    /// </summary>
    public string? RouteOfAdministration { get; set; }

    /// <summary>
    /// المؤشر الطبي - لماذا نعطي هذا الدواء؟
    /// مثال: "Bacterial Infection, Fever, Pain"
    /// </summary>
    public string? Indication { get; set; }

    /// <summary>
    /// التحذيرات والموانع الطبية
    /// مثال: "Avoid with hypertension, Monitor liver function"
    /// </summary>
    public string? WarningsAndContraindications { get; set; }

    /// <summary>
    /// خطر التفاعل مع أدوية أخرى - وصف نصي
    /// </summary>
    public string? DrugInteractionRisk { get; set; }

    public DateTime LastModifiedAt { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public Prescription? Prescription { get; set; }
}
