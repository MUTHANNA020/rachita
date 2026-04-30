using System;
using System.Text.Json.Serialization;

namespace Rachita.Core.Entities;

public class DrugInteraction
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// العيادة التي أضافت هذا التفاعل
    /// </summary>
    public Guid ClinicId { get; set; }

    /// <summary>
    /// الدواء الأول - مثال: "Amoxicillin"
    /// </summary>
    public string Drug1 { get; set; } = string.Empty;

    /// <summary>
    /// الدواء الثاني - مثال: "Metronidazole"
    /// ملاحظة: يتم التخزين بتشفير ليكون مستقل عن الترتيب
    /// Drug1 + Drug2 = Drug2 + Drug1
    /// </summary>
    public string Drug2 { get; set; } = string.Empty;

    /// <summary>
    /// درجة الخطورة
    /// 0 = Minor, 1 = Moderate, 2 = Severe, 3 = Contraindicated
    /// </summary>
    public int Severity { get; set; } = 0;

    /// <summary>
    /// وصف التفاعل الطبي - ما الذي يحدث عند أخذ الاثنين معاً
    /// مثال: "May increase risk of C. difficile infection"
    /// </summary>
    public string InteractionDescription { get; set; } = string.Empty;

    /// <summary>
    /// التوصيات الطبية - ماذا يفعل الطبيب؟
    /// مثال: "Use alternative to one of them" أو "Monitor closely"
    /// </summary>
    public string? Recommendation { get; set; }

    /// <summary>
    /// مصدر البيانات - من أين حصلنا على هذه المعلومة؟
    /// مثال: "FDA", "DrugBank", "Clinical Study", "Therapeutic Guidelines"
    /// </summary>
    public string? EvidenceSource { get; set; }

    /// <summary>
    /// هل هذا التفاعل نشط؟
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// متى تم إضافة هذا التفاعل
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// آخر تحديث
    /// </summary>
    public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public Clinic? Clinic { get; set; }
}

/// <summary>
/// مستويات خطورة التفاعلات الدوائية
/// </summary>
public enum DrugInteractionSeverity
{
    /// <summary>
    /// طفيف - لا يحتاج تدخل
    /// </summary>
    Minor = 0,

    /// <summary>
    /// متوسط - يحتاج مراقبة
    /// </summary>
    Moderate = 1,

    /// <summary>
    /// حاد - يحتاج تعديل الجرعة أو الخيار البديل
    /// </summary>
    Severe = 2,

    /// <summary>
    /// محظور تماماً - لا تعطي معاً
    /// </summary>
    Contraindicated = 3
}
