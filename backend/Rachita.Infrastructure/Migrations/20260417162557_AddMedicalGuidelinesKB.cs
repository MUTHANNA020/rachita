using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Rachita.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMedicalGuidelinesKB : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MedicalGuidelines",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RuleType = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TargetKeyword = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ConditionValue = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Severity = table.Column<int>(type: "int", nullable: false),
                    AlertTitle = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    AlertMessage = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Recommendation = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MedicalGuidelines", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "MedicalGuidelines",
                columns: new[] { "Id", "AlertMessage", "AlertTitle", "ConditionValue", "CreatedAt", "IsActive", "Recommendation", "RuleType", "Severity", "TargetKeyword" },
                values: new object[,]
                {
                    { new Guid("566af869-25f0-466d-886f-a5cadd7921a2"), "Amoxicillin محظور - المريض مسجل لديه حساسية من مجموعة البنسلين.", "⚠️ حساسية البنسلين!", "penicillin", new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "استخدم مضاد حيوي بديل من فئة Macrolide (مثل Azithromycin).", "Allergy", 2, "penicillin_to_amoxicillin" },
                    { new Guid("6d525fc0-f925-41e9-a3b0-2f96cfb05ebd"), "Misoprostol يسبب تقلصات رحمية عنيفة وإجهاض.", "🚨 خطر الإجهاض!", null, new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "ممنوع للحوامل إلا في حالات الإجهاض الطبي المتعمد.", "Pregnancy", 2, "misoprostol" },
                    { new Guid("7a612154-18f4-4dfa-bae0-1090f488de1d"), "يجب تعديل جرعات الأدوية الكلوية.", "⚙️ مريض قصور كلوي", null, new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "افحص الكرياتينين وعدل الجرعة تبعاً.", "ChronicDisease", 1, "كلى" },
                    { new Guid("b11ea2fb-e265-4f46-95fa-cc4360e7fcba"), "Methotrexate يسبب تشوهات جنينية خطيرة.", "🚨 محظور أثناء الحمل!", null, new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "يجب إيقاف الدواء فوراً والتواصل مع المختص.", "Pregnancy", 2, "methotrexate" },
                    { new Guid("b1f51ee8-c2b6-4ac4-95b7-7dc5e20dabb5"), "الأطفال أقل من 5 سنوات يحتاجون لحساب جرعات دقيق يعتمد على الوزن.", "👶 تنبيه الأطفال (< 5 سنوات)", "5", new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "استخدم صيغة mg/kg لحساب الجرعة وتأكد من التركيز المناسب (شراب/قطرات).", "PediatricAge", 1, "general" },
                    { new Guid("b8d2eb9d-dcb1-447a-ad85-ab54e3d3606a"), "يجب تعديل جرعات الأدوية التي تُطرح عن طريق الكلى.", "⚙️ مريض قصور كلوي", null, new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "استخدم حاسبة الجرعة المعتمدة على eGFR للمضادات الحيوية الخاصة.", "ChronicDisease", 1, "kidney" },
                    { new Guid("bd7db024-fbfa-42f1-aa15-842cdbcdce16"), "أدوية ACE محظورة لأنها تؤثر على كلى الجنين.", "⚠️ تحذير حمل", null, new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "استخدم بدائل آمنة لضغط الدم (مثل Methyldopa أو Labetalol).", "Pregnancy", 2, "ace inhibitor" },
                    { new Guid("dcff7cf6-3635-430c-ab2b-8739cf9d268a"), "Penicillin محظور - المريض مسجل لديه حساسية من هذا الدواء.", "⚠️ حساسية البنسلين!", "penicillin", new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "استخدم مضاد حيوي بديل من فئة Macrolide أو Cephalosporin متأخر.", "Allergy", 2, "penicillin_to_penicillin" },
                    { new Guid("eb0d4bae-fc09-4ff3-be76-3a7cb1d31c0a"), "Isotretinoin دواء مسخ فئة X.", "🚨 تشوهات جنينية!", null, new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "ممنوع قطعياً.", "Pregnancy", 2, "isotretinoin" },
                    { new Guid("ebf2a792-5d9c-48c0-8d5f-14fc7cfc4ae5"), "قد يعاني المرضى المسنون من انخفاض في التصفية الكلوية وحساسية متزايدة للأدوية (تأثير بنزوديازيبين، أدوية مضادة للكولين).", "👴 تنبيه كبار السن (> 65 سنة)", "65", new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "ابدأ بجرعة أقل بـ 50% (Start low, go slow) ويفضل فحص وظائف الكلى (eGFR).", "GeriatricAge", 1, "general" },
                    { new Guid("f9f06bf2-4114-41d3-a4c3-e29bc25def43"), "Warfarin محظور تماماً للحوامل (Teratogenic).", "🚨 محظور أثناء الحمل!", null, new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), true, "اختر دواء آمن من فئة A/B من FDA مثل Heparin.", "Pregnancy", 2, "warfarin" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MedicalGuidelines");
        }
    }
}
