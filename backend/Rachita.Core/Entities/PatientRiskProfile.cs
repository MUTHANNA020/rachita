using System;
using System.Text.Json.Serialization;

namespace Rachita.Core.Entities;

public class PatientRiskProfile
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// المريض المرتبط - One-to-One relationship
    /// </summary>
    public Guid PatientId { get; set; }

    /// <summary>
    /// الحالات الصحية المهمة
    /// </summary>
    public bool HasDiabetes { get; set; } = false;
    public bool HasHypertension { get; set; } = false;
    public bool HasHeartDisease { get; set; } = false;
    public bool HasKidneyDisease { get; set; } = false;
    public bool HasLiverDisease { get; set; } = false;
    public bool HasAsthma { get; set; } = false;
    public bool HasThyroidDisease { get; set; } = false;
    public bool HasAutoimmune { get; set; } = false;

    /// <summary>
    /// هل المريض يتناول مثبطات جهاز المناعة
    /// </summary>
    public bool OnImmunosuppressants { get; set; } = false;

    /// <summary>
    /// هل المريض يتناول مميعات الدم
    /// </summary>
    public bool OnAnticoagulants { get; set; } = false;

    /// <summary>
    /// حالات خاصة
    /// </summary>
    public bool IsPregnant { get; set; } = false;
    public bool IsBreastfeeding { get; set; } = false;
    public bool IsPostSurgery { get; set; } = false;

    /// <summary>
    /// يقيّم مستوى المخاطر الكلي للمريض
    /// Score من 0 إلى 100
    /// 0-20: منخفض
    /// 21-50: متوسط
    /// 51-80: عالي
    /// 81-100: حرج جداً
    /// </summary>
    public int RiskScore { get; set; } = 0;

    /// <summary>
    /// آخر تحديث لـ score
    /// </summary>
    public DateTime LastRiskAssessmentAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// ملاحظات خاصة عن المريض
    /// </summary>
    public string? SpecialNotes { get; set; }

    /// <summary>
    /// متى تم إنشاء الملف
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// آخر تحديث
    /// </summary>
    public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public Patient? Patient { get; set; }

    /// <summary>
    /// حساب مستوى المخاطر بناءً على الحالات الموجودة
    /// هذه دالة منطقية تحسب الـ Score
    /// </summary>
    public void CalculateRiskScore()
    {
        int score = 0;

        // الأمراض المزمنة
        if (HasDiabetes) score += 15;
        if (HasHypertension) score += 10;
        if (HasHeartDisease) score += 20;
        if (HasKidneyDisease) score += 20;
        if (HasLiverDisease) score += 20;
        if (HasAsthma) score += 8;
        if (HasThyroidDisease) score += 5;
        if (HasAutoimmune) score += 15;

        // الأدوية المهمة
        if (OnImmunosuppressants) score += 15;
        if (OnAnticoagulants) score += 12;

        // حالات خاصة
        if (IsPregnant) score += 25;
        if (IsBreastfeeding) score += 15;
        if (IsPostSurgery) score += 10;

        // تحديد مستوى المخاطر (كبار السن)
        // هذا يتطلب access إلى Patient.Age
        // يمكن إضافة parameter في future إذا لزم

        this.RiskScore = Math.Min(score, 100); // لا تتجاوز 100
    }
}
