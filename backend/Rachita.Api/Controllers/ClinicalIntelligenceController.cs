using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Rachita.Api.DTOs;
using Rachita.Infrastructure.Data;
using Rachita.Core.Entities;
using System.Text.Json;

namespace Rachita.Api.Controllers
{
    /// 🏥 Controller لإدارة التنبيهات السريرية والذكاء الطبي
    [ApiController]
    [Route("api/[controller]")]
    public class ClinicalIntelligenceController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<ClinicalIntelligenceController> _logger;

        public ClinicalIntelligenceController(
            AppDbContext context,
            ILogger<ClinicalIntelligenceController> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<IActionResult> CheckPrescriptionSafety(Guid prescriptionId)
        {
#pragma warning disable CS8602 // Dereference of a possibly null reference
            try
            {
                var prescription = await _context.Prescriptions
                    .Include(p => p.Patient)
                    .ThenInclude(p => p.PatientRiskProfile)
                    .Include(p => p.PrescriptionMedicines)
                    .FirstOrDefaultAsync(p => p.Id == prescriptionId);

                if (prescription == null)
                    return NotFound("الوصفة غير موجودة");

                var guidelines = await _context.MedicalGuidelines.Where(g => g.IsActive).ToListAsync();
                var alerts = new List<ClinicalAlert>();

                // 1️⃣ فحص تفاعلات الأدوية
                alerts.AddRange(CheckDrugInteractions(prescription));

                // 2️⃣ فحص الحساسيات بشكل ديناميكي
                alerts.AddRange(CheckAllergyContraindications(prescription, guidelines));

                // 3️⃣ فحص تحذيرات الحمل بشكل ديناميكي
                if (prescription.Patient?.IsPregnant == true)
                    alerts.AddRange(CheckPregnancyWarnings(prescription, guidelines));

                // 4️⃣ فحص تحذيرات العمر بشكل ديناميكي
                alerts.AddRange(CheckAgeSpecificAlerts(prescription, guidelines));

                // 5️⃣ فحص الأمراض المزمنة بشكل ديناميكي
                alerts.AddRange(CheckChronicDiseaseAlerts(prescription, guidelines));

                // حفظ التنبيهات
                if (alerts.Any())
                {
                    await _context.ClinicalAlerts.AddRangeAsync(alerts);
                    await _context.SaveChangesAsync();
                }

                return Ok(new
                {
                    prescriptionId,
                    alertCount = alerts.Count,
                    criticalCount = alerts.Count(a => a.Priority == (int)ClinicalAlertPriority.Critical),
                    alerts = alerts.Select(a => new
                    {
                        a.Id,
                        a.Title,
                        a.Message,
                        a.AlertType,
                        a.Priority,
                        a.Recommendation,
                        a.CreatedAt
                    })
                });


            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فحص سلامة الوصفة");
                return StatusCode(500, "خطأ في المعالجة");
            }
#pragma warning restore CS8602 // Dereference of a possibly null reference
        }

        /// 📊 الحصول على تنبيهات المريض
        [HttpGet("patients/{patientId}/alerts")]
        public async Task<IActionResult> GetPatientAlerts(Guid patientId)
        {
            var alerts = await _context.ClinicalAlerts
                .Where(a => a.PatientId == patientId)
                .OrderByDescending(a => a.Priority)
                .ThenByDescending(a => a.CreatedAt)
                .ToListAsync();

            var statistics = new
            {
                total = alerts.Count,
                unresolved = alerts.Count(a => !a.IsResolved),
                critical = alerts.Count(a => a.Priority == (int)ClinicalAlertPriority.Critical),
                warning = alerts.Count(a => a.Priority == (int)ClinicalAlertPriority.Warning),
                info = alerts.Count(a => a.Priority == (int)ClinicalAlertPriority.Info),
            };


            return Ok(new { statistics, alerts });
        }

        /// 🚨 الحصول على التنبيهات الحرجة للعيادة
        [HttpGet("clinics/{clinicId}/critical-alerts")]
        public async Task<IActionResult> GetCriticalAlerts(Guid clinicId)
        {
            var criticalAlerts = await _context.ClinicalAlerts
                .Include(a => a.Patient)
                .Where(a => a.ClinicId == clinicId &&
                            a.Priority == (int)ClinicalAlertPriority.Critical &&
                            !a.IsResolved)
                            .OrderByDescending(a => a.CreatedAt)
                            .Take(50)
                            .ToListAsync();

            return Ok(new
            {
                count = criticalAlerts.Count,
                alerts = criticalAlerts.Select(a => new
                {
                    a.Id,
                    a.Title,
                    a.Message,
                    patientName = a.Patient?.Name,
                    a.AlertType,
                    a.Recommendation,
                    a.CreatedAt
                })
            });

        }

        /// ✔️ تعليم تنبيه كمحل
        [HttpPut("alerts/{alertId}/resolve")]
        public async Task<IActionResult> ResolveAlert(Guid alertId, [FromBody] ResolveAlertRequest request)
        {
            var alert = await _context.ClinicalAlerts.FindAsync(alertId);
            if (alert == null)
                return NotFound("التنبيه غير موجود");

            alert.IsResolved = true;
            alert.ResolvedAt = DateTime.UtcNow;
            alert.ResolutionNotes = request.ResolutionNotes;

            await _context.SaveChangesAsync();

            return Ok(new { message = "تم تعليم التنبيه", alert });
        }

        /// 💊 الحصول على تفاعلات الأدوية المعروفة
        [HttpGet("drug-interactions")]
        public IActionResult GetDrugInteractions([FromQuery] string drug1, [FromQuery] string drug2)
        {
            var interaction = _context.DrugInteractions
                .AsEnumerable()
                .FirstOrDefault(di =>
                    (di.Drug1.ToLower() == drug1.ToLower() && di.Drug2.ToLower() == drug2.ToLower()) ||
                    (di.Drug1.ToLower() == drug2.ToLower() && di.Drug2.ToLower() == drug1.ToLower()));

            if (interaction == null)
                return Ok(new { hasInteraction = false });

            return Ok(new
            {
                hasInteraction = true,
                severity = interaction.Severity,
                description = interaction.InteractionDescription,
                recommendation = interaction.Recommendation,
                evidenceSource = interaction.EvidenceSource
            });
        }

        /// 🔍 فحص قائمة أدوية كاملة
        [HttpPost("check-drug-interactions")]
        public async Task<IActionResult> CheckMultipleDrugInteractions(
            [FromBody] CheckInteractionsRequest request)
        {
            var interactions = new List<object>();

            for (int i = 0; i < request.Medicines.Count; i++)
            {
                for (int j = i + 1; j < request.Medicines.Count; j++)
                {
                    var interaction = _context.DrugInteractions
                        .AsEnumerable()
                        .FirstOrDefault(di =>
                            (di.Drug1.ToLower().Contains(request.Medicines[i].ToLower()) &&
                             di.Drug2.ToLower().Contains(request.Medicines[j].ToLower())) ||
                            (di.Drug1.ToLower().Contains(request.Medicines[j].ToLower()) &&
                             di.Drug2.ToLower().Contains(request.Medicines[i].ToLower())));

                    if (interaction != null)
                    {
                        interactions.Add(new
                        {
                            drug1 = request.Medicines[i],
                            drug2 = request.Medicines[j],
                            severity = interaction.Severity,
                            description = interaction.InteractionDescription,
                            recommendation = interaction.Recommendation
                        });
                    }
                }
            }

            return Ok(new
            {
                totalMedicines = request.Medicines.Count,
                interactionCount = interactions.Count,
                hasCritical = interactions.OfType<dynamic>()
                    .Any(i => (int)i.severity >= 3), // 3 = Critical
                interactions
            });
        }

        /// 📋 الحصول على قوالب الأدوية للعيادة
        [HttpGet("clinics/{clinicId}/medication-templates")]
        public async Task<IActionResult> GetMedicationTemplates(Guid clinicId, [FromQuery] string? specialty = null)
        {
            var query = _context.MedicationTemplates
                .Where(mt => mt.ClinicId == clinicId && mt.IsActive);

            if (!string.IsNullOrEmpty(specialty))
                query = query.Where(mt => mt.Specialty == specialty);

            var templates = await query
                .OrderByDescending(mt => mt.LastUsedAt)
                .ToListAsync();

            return Ok(templates.Select(t => new
            {
                t.Id,
                t.Name,
                t.Description,
                t.Specialty,
                medicines = JsonSerializer.Deserialize<List<dynamic>>(t.MedicinesJson),
                t.UsageCount,
                t.LastUsedAt
            }));
        }

        /// ➕ إنشاء قالب أدوية جديد
        [HttpPost("clinics/{clinicId}/medication-templates")]
        public async Task<IActionResult> CreateMedicationTemplate(
            Guid clinicId,
            [FromBody] CreateTemplateRequest request)
        {
            var template = new MedicationTemplate
            {
                Id = Guid.NewGuid(),
                ClinicId = clinicId,
                Name = request.Name,
                Description = request.Description,
                Specialty = request.Specialty,
                MedicinesJson = JsonSerializer.Serialize(request.Medicines),
                IsActive = true,
                UsageCount = 0,
                Version = 1,
                CreatedAt = DateTime.UtcNow,
                LastUpdatedAt = DateTime.UtcNow
            };

            _context.MedicationTemplates.Add(template);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetMedicationTemplates), template);
        }

        // ============================================
        // 🔍 Methods خاصة للفحص
        // ============================================

        private List<ClinicalAlert> CheckDrugInteractions(Prescription prescription)
        {
            var alerts = new List<ClinicalAlert>();
            var medicines = prescription.PrescriptionMedicines
                .Select(pm => pm.MedicineName.ToLower())
                .ToList();

            for (int i = 0; i < medicines.Count; i++)
            {
                for (int j = i + 1; j < medicines.Count; j++)
                {
                    var interaction = _context.DrugInteractions
                        .FirstOrDefault(di =>
                            (di.Drug1.ToLower() == medicines[i] && di.Drug2.ToLower() == medicines[j]) ||
                            (di.Drug1.ToLower() == medicines[j] && di.Drug2.ToLower() == medicines[i]));

                    if (interaction != null && interaction.IsActive)
                    {
                        alerts.Add(new ClinicalAlert
                        {
                            Id = Guid.NewGuid(),
                            ClinicId = prescription.ClinicId,
                            PatientId = prescription.PatientId,
                            PrescriptionId = prescription.Id,
                            AlertType = (int)ClinicalAlertType.DrugInteraction,
                            Priority = interaction.Severity,
                            Title = $"تفاعل: {medicines[i]} + {medicines[j]}",
                            Message = interaction.InteractionDescription,
                            Recommendation = interaction.Recommendation,
                            IsResolved = false,
                            CreatedAt = DateTime.UtcNow,
                            LastUpdatedAt = DateTime.UtcNow
                        });
                    }
                }
            }

            return alerts;
        }

        private List<ClinicalAlert> CheckAllergyContraindications(Prescription prescription, List<MedicalGuideline> guidelines)
        {
            var alerts = new List<ClinicalAlert>();
            var allergies = prescription.Patient?.Allergies?.ToLower() ?? "";
            var medicines = prescription.PrescriptionMedicines
                .Select(pm => pm.MedicineName.ToLower())
                .ToList();

            var allergyRules = guidelines.Where(g => g.RuleType == GuidelineRuleTypes.Allergy).ToList();

            foreach (var rule in allergyRules)
            {
                if (!string.IsNullOrEmpty(rule.ConditionValue) && allergies.Contains(rule.ConditionValue.ToLower()))
                {
                    // If patient has this allergy, check if any prescribed medicine matches the cross-reactivity target
                    foreach (var medicine in medicines)
                    {
                        var targetKw = rule.TargetKeyword.Split("_to_").LastOrDefault() ?? rule.TargetKeyword;
                        if (medicine.Contains(targetKw.ToLower()))
                        {
                            alerts.Add(new ClinicalAlert
                            {
                                Id = Guid.NewGuid(),
                                ClinicId = prescription.ClinicId,
                                PatientId = prescription.PatientId,
                                PrescriptionId = prescription.Id,
                                AlertType = (int)ClinicalAlertType.AllergicReaction,
                                Priority = rule.Severity,
                                Title = rule.AlertTitle,
                                Message = rule.AlertMessage,
                                Recommendation = rule.Recommendation,
                                IsResolved = false,
                                CreatedAt = DateTime.UtcNow,
                                LastUpdatedAt = DateTime.UtcNow
                            });
                        }
                    }
                }
            }

            return alerts;
        }

        private List<ClinicalAlert> CheckPregnancyWarnings(Prescription prescription, List<MedicalGuideline> guidelines)
        {
            var alerts = new List<ClinicalAlert>();
            var pregnancyRules = guidelines.Where(g => g.RuleType == GuidelineRuleTypes.Pregnancy).ToList();

            foreach (var medicine in prescription.PrescriptionMedicines)
            {
                var medLower = medicine.MedicineName.ToLower();

                var matchedRule = pregnancyRules.FirstOrDefault(r => medLower.Contains(r.TargetKeyword.ToLower()));
                if (matchedRule != null)
                {
                    alerts.Add(new ClinicalAlert
                    {
                        Id = Guid.NewGuid(),
                        ClinicId = prescription.ClinicId,
                        PatientId = prescription.PatientId,
                        PrescriptionId = prescription.Id,
                        AlertType = (int)ClinicalAlertType.PregnancyWarning,
                        Priority = matchedRule.Severity,
                        Title = matchedRule.AlertTitle,
                        Message = matchedRule.AlertMessage,
                        Recommendation = matchedRule.Recommendation,
                        IsResolved = false,
                        CreatedAt = DateTime.UtcNow,
                        LastUpdatedAt = DateTime.UtcNow
                    });
                }
            }

            return alerts;
        }

        private List<ClinicalAlert> CheckAgeSpecificAlerts(Prescription prescription, List<MedicalGuideline> guidelines)
        {
            var alerts = new List<ClinicalAlert>();
            var age = prescription.Patient?.Age;

            if (!age.HasValue) return alerts;

            var pediatricRules = guidelines.Where(g => g.RuleType == GuidelineRuleTypes.PediatricAge).ToList();
            var geriatricRules = guidelines.Where(g => g.RuleType == GuidelineRuleTypes.GeriatricAge).ToList();

            foreach (var rule in pediatricRules)
            {
                if (int.TryParse(rule.ConditionValue, out int ageLimit) && age < ageLimit)
                {
                    alerts.Add(new ClinicalAlert
                    {
                        Id = Guid.NewGuid(),
                        ClinicId = prescription.ClinicId,
                        PatientId = prescription.PatientId,
                        PrescriptionId = prescription.Id,
                        AlertType = (int)ClinicalAlertType.AgeInappropriate,
                        Priority = rule.Severity,
                        Title = rule.AlertTitle,
                        Message = rule.AlertMessage,
                        Recommendation = rule.Recommendation,
                        IsResolved = false,
                        CreatedAt = DateTime.UtcNow,
                        LastUpdatedAt = DateTime.UtcNow
                    });
                }
            }

            foreach (var rule in geriatricRules)
            {
                if (int.TryParse(rule.ConditionValue, out int ageLimit) && age > ageLimit)
                {
                    alerts.Add(new ClinicalAlert
                    {
                        Id = Guid.NewGuid(),
                        ClinicId = prescription.ClinicId,
                        PatientId = prescription.PatientId,
                        PrescriptionId = prescription.Id,
                        AlertType = (int)ClinicalAlertType.AgeInappropriate,
                        Priority = rule.Severity,
                        Title = rule.AlertTitle,
                        Message = rule.AlertMessage,
                        Recommendation = rule.Recommendation,
                        IsResolved = false,
                        CreatedAt = DateTime.UtcNow,
                        LastUpdatedAt = DateTime.UtcNow
                    });
                }
            }

            return alerts;
        }

        private List<ClinicalAlert> CheckChronicDiseaseAlerts(Prescription prescription, List<MedicalGuideline> guidelines)
        {
            var alerts = new List<ClinicalAlert>();
            var chronic = prescription.Patient?.ChronicDiseases?.ToLower() ?? "";
            
            if (string.IsNullOrWhiteSpace(chronic)) return alerts;

            var diseaseRules = guidelines.Where(g => g.RuleType == GuidelineRuleTypes.ChronicDisease).ToList();

            foreach (var rule in diseaseRules)
            {
                if (chronic.Contains(rule.TargetKeyword.ToLower()))
                {
                    alerts.Add(new ClinicalAlert
                    {
                        Id = Guid.NewGuid(),
                        ClinicId = prescription.ClinicId,
                        PatientId = prescription.PatientId,
                        PrescriptionId = prescription.Id,
                        AlertType = (int)ClinicalAlertType.ContraindicatedCondition,
                        Priority = rule.Severity,
                        Title = rule.AlertTitle,
                        Message = rule.AlertMessage,
                        Recommendation = rule.Recommendation,
                        IsResolved = false,
                        CreatedAt = DateTime.UtcNow,
                        LastUpdatedAt = DateTime.UtcNow
                    });
                }
            }

            return alerts;
        }
    }

    // ============================================
    // 📋 DTOs
    // ============================================

    public class ResolveAlertRequest
    {
        public string? ResolutionNotes { get; set; }
    }

    public class CheckInteractionsRequest
    {
        public List<string> Medicines { get; set; } = new();
    }

    public class CreateTemplateRequest
    {
        public required string Name { get; set; }
        public string? Description { get; set; }
        public string? Specialty { get; set; }
        public List<object> Medicines { get; set; } = new();
    }
}
