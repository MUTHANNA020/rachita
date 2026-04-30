using System;
using System.Text.Json.Serialization;

namespace Rachita.Core.Entities;

public class ClinicalAlert
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// العيادة التي تحتوي على هذا التنبيه
    /// </summary>
    public Guid ClinicId { get; set; }

    /// <summary>
    /// المريض المتعلق بالتنبيه (اختياري)
    /// </summary>
    public Guid? PatientId { get; set; }

    /// <summary>
    /// الوصفة المتعلقة بالتنبيه (اختياري)
    /// </summary>
    public Guid? PrescriptionId { get; set; }

    /// <summary>
    /// نوع التنبيه
    /// 0 = AllergicReaction
    /// 1 = DrugInteraction
    /// 2 = ContraindicatedCondition
    /// 3 = DosageWarning
    /// 4 = LongTermRisk
    /// 5 = AgeInappropriate
    /// 6 = PregnancyWarning
    /// 7 = KidneyFunction
    /// 8 = LiverFunction
    /// </summary>
    public int AlertType { get; set; } = 0;

    /// <summary>
    /// مستوى الأهمية
    /// 0 = Info (معلومة عادية)
    /// 1 = Warning (تحذير - يحتاج انتباه)
    /// 2 = Critical (حرج - فوري جداً)
    /// </summary>
    public int Priority { get; set; } = 1;

    /// <summary>
    /// عنوان التنبيه
    /// مثال: "تفاعل دوائي خطر محتمل"
    /// </summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// وصف التنبيه بالتفصيل
    /// مثال: "المريض لديه حساسية من البنسلين والدواء المختار يحتوي على بنسلين"
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// التوصيات - ماذا يجب عمله
    /// مثال: "استخدم Cephalosporin بدلاً منه"
    /// </summary>
    public string? Recommendation { get; set; }

    /// <summary>
    /// هل تم حل/معالجة التنبيه
    /// </summary>
    public bool IsResolved { get; set; } = false;

    /// <summary>
    /// متى تم حل التنبيه
    /// </summary>
    public DateTime? ResolvedAt { get; set; }

    /// <summary>
    /// ملاحظات حول كيفية حل المشكلة
    /// </summary>
    public string? ResolutionNotes { get; set; }

    /// <summary>
    /// متى تم إنشاء التنبيه
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// آخر تحديث
    /// </summary>
    public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public Clinic? Clinic { get; set; }

    [JsonIgnore]
    public Patient? Patient { get; set; }

    [JsonIgnore]
    public Prescription? Prescription { get; set; }
}

/// <summary>
/// أنواع التنبيهات السريرية
/// </summary>
public enum ClinicalAlertType
{
    /// <summary>
    /// رد فعل تحسسي محتمل
    /// </summary>
    AllergicReaction = 0,

    /// <summary>
    /// تفاعل بين أدوية
    /// </summary>
    DrugInteraction = 1,

    /// <summary>
    /// حالة صحية تمنع استخدام هذا الدواء
    /// </summary>
    ContraindicatedCondition = 2,

    /// <summary>
    /// تحذير من جرعة غير مناسبة
    /// </summary>
    DosageWarning = 3,

    /// <summary>
    /// خطر من الاستخدام طويل الأجل
    /// </summary>
    LongTermRisk = 4,

    /// <summary>
    /// الدواء غير مناسب لفئة عمر المريض
    /// </summary>
    AgeInappropriate = 5,

    /// <summary>
    /// تحذير خاص بالحمل
    /// </summary>
    PregnancyWarning = 6,

    /// <summary>
    /// تحذير يتعلق بوظائف الكلى
    /// </summary>
    KidneyFunction = 7,

    /// <summary>
    /// تحذير يتعلق بوظائف الكبد
    /// </summary>
    LiverFunction = 8
}

/// <summary>
/// مستويات أهمية التنبيهات
/// </summary>
public enum ClinicalAlertPriority
{
    /// <summary>
    /// معلومة عادية - للإطلاع فقط
    /// </summary>
    Info = 0,

    /// <summary>
    /// تحذير - يحتاج انتباه الطبيب قبل الوصفة
    /// </summary>
    Warning = 1,

    /// <summary>
    /// حرج - فوري جداً، قد يكون خطيراً على الحياة
    /// </summary>
    Critical = 2
}
