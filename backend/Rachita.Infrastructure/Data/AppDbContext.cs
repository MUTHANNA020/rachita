using Microsoft.EntityFrameworkCore;
using Rachita.Core.Entities;
namespace Rachita.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
        
    }

    public DbSet<Clinic> Clinics { get; set; } = null!;
    public DbSet<User> Users { get; set; } = null!;
    public DbSet<Patient> Patients { get; set; } = null!;
    public DbSet<Prescription> Prescriptions { get; set; } = null!;
    public DbSet<VitalSign> VitalSigns { get; set; } = null!;
    public DbSet<PrescriptionMedicine> PrescriptionMedicines { get; set; } = null!;
    public DbSet<SyncAuditLog> SyncAuditLogs { get; set; } = null!;
    public DbSet<DoctorProfile> DoctorProfiles { get; set; } = null!;

    // 🏥 DbSets الجديدة - الذكاء الطبي
    public DbSet<DrugInteraction> DrugInteractions { get; set; } = null!;
    public DbSet<PatientRiskProfile> PatientRiskProfiles { get; set; } = null!;
    public DbSet<MedicationTemplate> MedicationTemplates { get; set; } = null!;
    public DbSet<ClinicalAlert> ClinicalAlerts { get; set; } = null!;

    // 🏥 مكتبة الذكاء الطبي الديناميكية
    public DbSet<MedicalGuideline> MedicalGuidelines { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ==========================================
        // One-to-Many والـ One-to-One configurations
        // ==========================================
        modelBuilder.Entity<Clinic>().HasMany(c => c.Users).WithOne(u => u.Clinic).HasForeignKey(u => u.ClinicId);
        modelBuilder.Entity<Clinic>().HasMany(c => c.Patients).WithOne(p => p.Clinic).HasForeignKey(p => p.ClinicId);
        
        // One-to-One Clinic to DoctorProfile
        modelBuilder.Entity<Clinic>().HasOne<DoctorProfile>().WithOne(dp => dp.Clinic).HasForeignKey<DoctorProfile>(dp => dp.ClinicId);

        // Patient Prescriptions
        modelBuilder.Entity<Patient>().HasMany(p => p.Prescriptions).WithOne(pr => pr.Patient).HasForeignKey(pr => pr.PatientId);
        
        // Prescription relations
        modelBuilder.Entity<Prescription>().HasOne(p => p.VitalSign).WithOne(v => v.Prescription).HasForeignKey<VitalSign>(v => v.PrescriptionId);
        modelBuilder.Entity<Prescription>().HasMany(p => p.PrescriptionMedicines).WithOne(m => m.Prescription).HasForeignKey(m => m.PrescriptionId);

        // Fix for multiple cascade paths in SQL Server
        modelBuilder.Entity<Prescription>()
            .HasOne(p => p.Doctor)
            .WithMany()
            .HasForeignKey(p => p.DoctorId)
            .OnDelete(DeleteBehavior.Restrict);

        // ==========================================
        // 🏥 العلاقات الطبية الجديدة
        // ==========================================

        // DrugInteraction - Many-to-One with Clinic
        modelBuilder.Entity<DrugInteraction>()
            .HasOne(di => di.Clinic)
            .WithMany()
            .HasForeignKey(di => di.ClinicId)
            .OnDelete(DeleteBehavior.Restrict);

        // Unique constraint على DrugInteraction
        // تجنب التكرار (A+B = B+A يعتبر نفس التفاعل)
        modelBuilder.Entity<DrugInteraction>()
            .HasIndex(d => new { d.Drug1, d.Drug2, d.ClinicId })
            .IsUnique()
.HasDatabaseName("IX_DrugInteraction_Unique");

        // PatientRiskProfile - One-to-One with Patient
        modelBuilder.Entity<PatientRiskProfile>()
            .HasOne(pr => pr.Patient)
            .WithOne(p => p.PatientRiskProfile)  // One-to-One
            .HasForeignKey<PatientRiskProfile>(pr => pr.PatientId)
            .OnDelete(DeleteBehavior.Cascade);

        // Unique index على PatientId
        modelBuilder.Entity<PatientRiskProfile>()
            .HasIndex(pr => pr.PatientId)
            .IsUnique()
.HasDatabaseName("IX_PatientRiskProfile_PatientId_Unique");

        // MedicationTemplate - Many-to-One with Clinic
        modelBuilder.Entity<MedicationTemplate>()
            .HasOne(mt => mt.Clinic)
            .WithMany()
            .HasForeignKey(mt => mt.ClinicId)
            .OnDelete(DeleteBehavior.Restrict);

        // ClinicalAlert - Multiple relationships
        modelBuilder.Entity<ClinicalAlert>()
            .HasOne(ca => ca.Clinic)
            .WithMany()
            .HasForeignKey(ca => ca.ClinicId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ClinicalAlert>()
            .HasOne(ca => ca.Patient)
            .WithMany()
            .HasForeignKey(ca => ca.PatientId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ClinicalAlert>()
            .HasOne(ca => ca.Prescription)
            .WithMany()
            .HasForeignKey(ca => ca.PrescriptionId)
            .OnDelete(DeleteBehavior.Restrict);

        // ==========================================
        // Column Configurations - النوع والحدود الأقصى
        // ==========================================

        // Patient - Text fields بدون حد أقصى
        modelBuilder.Entity<Patient>()
            .Property(p => p.Allergies)
            .HasColumnType("nvarchar(max)");

        modelBuilder.Entity<Patient>()
            .Property(p => p.ChronicDiseases)
            .HasColumnType("nvarchar(max)");

        modelBuilder.Entity<Patient>()
            .Property(p => p.MedicationHistoryJson)
            .HasColumnType("nvarchar(max)");

        modelBuilder.Entity<Patient>()
            .Property(p => p.CurrentMedicationsJson)
            .HasColumnType("nvarchar(max)");

        modelBuilder.Entity<Patient>()
            .Property(p => p.PreexistingConditionsJson)
            .HasColumnType("nvarchar(max)");

        // PrescriptionMedicine - Text fields
        modelBuilder.Entity<PrescriptionMedicine>()
            .Property(pm => pm.WarningsAndContraindications)
            .HasColumnType("nvarchar(max)");

        // DrugInteraction - Text fields
        modelBuilder.Entity<DrugInteraction>()
            .Property(di => di.InteractionDescription)
            .HasColumnType("nvarchar(max)");

        // MedicationTemplate - JSON
        modelBuilder.Entity<MedicationTemplate>()
            .Property(mt => mt.MedicinesJson)
            .HasColumnType("nvarchar(max)");

        // ClinicalAlert - Text fields
        modelBuilder.Entity<ClinicalAlert>()
            .Property(ca => ca.Message)
            .HasColumnType("nvarchar(max)");

        modelBuilder.Entity<ClinicalAlert>()
            .Property(ca => ca.Recommendation)
            .HasColumnType("nvarchar(max)");

        // ==========================================
        // Indexes - للبحث السريع والـ Performance
        // ==========================================

        // Patient Indexes
        modelBuilder.Entity<Patient>().HasIndex(p => p.Name);
        modelBuilder.Entity<Patient>().HasIndex(p => p.Phone);
        modelBuilder.Entity<Patient>().HasIndex(p => p.ClinicId);

        // DrugInteraction Indexes
        modelBuilder.Entity<DrugInteraction>().HasIndex(di => di.ClinicId);
        modelBuilder.Entity<DrugInteraction>().HasIndex(di => di.IsActive);
        modelBuilder.Entity<DrugInteraction>().HasIndex(di => new { di.Drug1, di.Drug2 });

        // MedicationTemplate Indexes
        modelBuilder.Entity<MedicationTemplate>().HasIndex(mt => mt.ClinicId);
        modelBuilder.Entity<MedicationTemplate>().HasIndex(mt => mt.IsActive);
        modelBuilder.Entity<MedicationTemplate>().HasIndex(mt => mt.Specialty);

        // ClinicalAlert Indexes
        modelBuilder.Entity<ClinicalAlert>().HasIndex(ca => ca.ClinicId);
        modelBuilder.Entity<ClinicalAlert>().HasIndex(ca => ca.PatientId);
        modelBuilder.Entity<ClinicalAlert>().HasIndex(ca => ca.PrescriptionId);
        modelBuilder.Entity<ClinicalAlert>().HasIndex(ca => ca.IsResolved);
        modelBuilder.Entity<ClinicalAlert>().HasIndex(ca => ca.Priority);
        modelBuilder.Entity<ClinicalAlert>().HasIndex(ca => ca.CreatedAt);

        // Sync Logs indexing for delta pulls
        modelBuilder.Entity<SyncAuditLog>().HasIndex(l => l.Timestamp);

        // ==========================================
        // 🧪 Seed Medical Guidelines (البيانات الأولية للقواعد الطبية)
        // ==========================================
        modelBuilder.Entity<MedicalGuideline>().HasData(
            // --- Pregnancy Warnings ---
            new MedicalGuideline { Id = Guid.Parse("f9f06bf2-4114-41d3-a4c3-e29bc25def43"), RuleType = GuidelineRuleTypes.Pregnancy, TargetKeyword = "warfarin", Severity = 2, AlertTitle = "🚨 محظور أثناء الحمل!", AlertMessage = "Warfarin محظور تماماً للحوامل (Teratogenic).", Recommendation = "اختر دواء آمن من فئة A/B من FDA مثل Heparin." },
            new MedicalGuideline { Id = Guid.Parse("b11ea2fb-e265-4f46-95fa-cc4360e7fcba"), RuleType = GuidelineRuleTypes.Pregnancy, TargetKeyword = "methotrexate", Severity = 2, AlertTitle = "🚨 محظور أثناء الحمل!", AlertMessage = "Methotrexate يسبب تشوهات جنينية خطيرة.", Recommendation = "يجب إيقاف الدواء فوراً والتواصل مع المختص." },
            new MedicalGuideline { Id = Guid.Parse("eb0d4bae-fc09-4ff3-be76-3a7cb1d31c0a"), RuleType = GuidelineRuleTypes.Pregnancy, TargetKeyword = "isotretinoin", Severity = 2, AlertTitle = "🚨 تشوهات جنينية!", AlertMessage = "Isotretinoin دواء مسخ فئة X.", Recommendation = "ممنوع قطعياً." },
            new MedicalGuideline { Id = Guid.Parse("6d525fc0-f925-41e9-a3b0-2f96cfb05ebd"), RuleType = GuidelineRuleTypes.Pregnancy, TargetKeyword = "misoprostol", Severity = 2, AlertTitle = "🚨 خطر الإجهاض!", AlertMessage = "Misoprostol يسبب تقلصات رحمية عنيفة وإجهاض.", Recommendation = "ممنوع للحوامل إلا في حالات الإجهاض الطبي المتعمد." },
            new MedicalGuideline { Id = Guid.Parse("bd7db024-fbfa-42f1-aa15-842cdbcdce16"), RuleType = GuidelineRuleTypes.Pregnancy, TargetKeyword = "ace inhibitor", Severity = 2, AlertTitle = "⚠️ تحذير حمل", AlertMessage = "أدوية ACE محظورة لأنها تؤثر على كلى الجنين.", Recommendation = "استخدم بدائل آمنة لضغط الدم (مثل Methyldopa أو Labetalol)." },

            // --- Allergies (Cross-Reactivity examples) ---
            new MedicalGuideline { Id = Guid.Parse("566af869-25f0-466d-886f-a5cadd7921a2"), RuleType = GuidelineRuleTypes.Allergy, TargetKeyword = "penicillin_to_amoxicillin", ConditionValue = "penicillin", AlertTitle = "⚠️ حساسية البنسلين!", AlertMessage = "Amoxicillin محظور - المريض مسجل لديه حساسية من مجموعة البنسلين.", Recommendation = "استخدم مضاد حيوي بديل من فئة Macrolide (مثل Azithromycin).", Severity = 2 },
            new MedicalGuideline { Id = Guid.Parse("dcff7cf6-3635-430c-ab2b-8739cf9d268a"), RuleType = GuidelineRuleTypes.Allergy, TargetKeyword = "penicillin_to_penicillin", ConditionValue = "penicillin", AlertTitle = "⚠️ حساسية البنسلين!", AlertMessage = "Penicillin محظور - المريض مسجل لديه حساسية من هذا الدواء.", Recommendation = "استخدم مضاد حيوي بديل من فئة Macrolide أو Cephalosporin متأخر.", Severity = 2 },

            // --- Pediatric Rules ---
            new MedicalGuideline { Id = Guid.Parse("b1f51ee8-c2b6-4ac4-95b7-7dc5e20dabb5"), RuleType = GuidelineRuleTypes.PediatricAge, TargetKeyword = "general", ConditionValue = "5", AlertTitle = "👶 تنبيه الأطفال (< 5 سنوات)", AlertMessage = "الأطفال أقل من 5 سنوات يحتاجون لحساب جرعات دقيق يعتمد على الوزن.", Recommendation = "استخدم صيغة mg/kg لحساب الجرعة وتأكد من التركيز المناسب (شراب/قطرات).", Severity = 1 },

            // --- Geriatric Rules ---
            new MedicalGuideline { Id = Guid.Parse("ebf2a792-5d9c-48c0-8d5f-14fc7cfc4ae5"), RuleType = GuidelineRuleTypes.GeriatricAge, TargetKeyword = "general", ConditionValue = "65", AlertTitle = "👴 تنبيه كبار السن (> 65 سنة)", AlertMessage = "قد يعاني المرضى المسنون من انخفاض في التصفية الكلوية وحساسية متزايدة للأدوية (تأثير بنزوديازيبين، أدوية مضادة للكولين).", Recommendation = "ابدأ بجرعة أقل بـ 50% (Start low, go slow) ويفضل فحص وظائف الكلى (eGFR).", Severity = 1 },

            // --- Chronic Disease Warnings ---
            new MedicalGuideline { Id = Guid.Parse("b8d2eb9d-dcb1-447a-ad85-ab54e3d3606a"), RuleType = GuidelineRuleTypes.ChronicDisease, TargetKeyword = "kidney", AlertTitle = "⚙️ مريض قصور كلوي", AlertMessage = "يجب تعديل جرعات الأدوية التي تُطرح عن طريق الكلى.", Recommendation = "استخدم حاسبة الجرعة المعتمدة على eGFR للمضادات الحيوية الخاصة.", Severity = 1 },
            new MedicalGuideline { Id = Guid.Parse("7a612154-18f4-4dfa-bae0-1090f488de1d"), RuleType = GuidelineRuleTypes.ChronicDisease, TargetKeyword = "كلى", AlertTitle = "⚙️ مريض قصور كلوي", AlertMessage = "يجب تعديل جرعات الأدوية الكلوية.", Recommendation = "افحص الكرياتينين وعدل الجرعة تبعاً.", Severity = 1 }
        );
    }
}

