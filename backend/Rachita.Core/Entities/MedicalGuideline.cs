using System;
using System.ComponentModel.DataAnnotations;

namespace Rachita.Core.Entities;

/// <summary>
/// يمثل قاعدة معرفية طبية للتحذيرات والتنبيهات المخصصة
/// يستخدم لاستبدال القيم الثابتة في الكود (Hardcoded Values)
/// </summary>
public class MedicalGuideline
{
    [Key]
    public Guid Id { get; set; }

    /// <summary>
    /// نوع القاعدة (مثلاً: Allergy, Pregnancy, Pediatric, Geriatric, Chronic)
    /// </summary>
    public string RuleType { get; set; } = string.Empty;

    /// <summary>
    /// الكلمة المستهدفة في العلاج أو المرض (مثل: "penicillin", "warfarin", "kidney")
    /// </summary>
    public string TargetKeyword { get; set; } = string.Empty;

    /// <summary>
    /// قيمة إضافية للشرط (مثل العمر 5 للأطفال، أو 65 لكبار السن)
    /// </summary>
    public string? ConditionValue { get; set; }

    /// <summary>
    /// مستوى الخطورة (0: Info, 1: Warning, 2: Critical) 
    /// يطابق ClinicalAlertPriority
    /// </summary>
    public int Severity { get; set; } = 1;

    /// <summary>
    /// عنوان التنبيه ليظهر للطبيب
    /// </summary>
    public string AlertTitle { get; set; } = string.Empty;

    /// <summary>
    /// وصف المشكلة الطبي
    /// </summary>
    public string AlertMessage { get; set; } = string.Empty;

    /// <summary>
    /// التوصية الطبية (البديل الممكن أو الخطوة التالية)
    /// </summary>
    public string Recommendation { get; set; } = string.Empty;

    /// <summary>
    /// هل القاعدة مفعلة؟
    /// </summary>
    public bool IsActive { get; set; } = true;
    
    public DateTime CreatedAt { get; set; }
}

public static class GuidelineRuleTypes
{
    public const string Allergy = "Allergy";
    public const string Pregnancy = "Pregnancy";
    public const string PediatricAge = "PediatricAge";
    public const string GeriatricAge = "GeriatricAge";
    public const string ChronicDisease = "ChronicDisease";
}
