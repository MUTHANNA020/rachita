using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Rachita.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMedicalIntelligence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ==========================================
            // 🏥 تحديث جدول Patients
            // ==========================================
            migrationBuilder.AddColumn<string>(
                name: "Allergies",
                table: "Patients",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ChronicDiseases",
                table: "Patients",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BloodGroup",
                table: "Patients",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Height",
                table: "Patients",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsPregnant",
                table: "Patients",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "AgeCategory",
                table: "Patients",
                type: "int",
                nullable: false,
                defaultValue: 2); // Default: Adult

            migrationBuilder.AddColumn<string>(
                name: "MedicationHistoryJson",
                table: "Patients",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "[]");

            migrationBuilder.AddColumn<string>(
                name: "CurrentMedicationsJson",
                table: "Patients",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "[]");

            migrationBuilder.AddColumn<string>(
                name: "PreexistingConditionsJson",
                table: "Patients",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "[]");

            // ==========================================
            // 🏥 تحديث جدول PrescriptionMedicines
            // ==========================================
            migrationBuilder.AddColumn<string>(
                name: "RouteOfAdministration",
                table: "PrescriptionMedicines",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Indication",
                table: "PrescriptionMedicines",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "WarningsAndContraindications",
                table: "PrescriptionMedicines",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DrugInteractionRisk",
                table: "PrescriptionMedicines",
                type: "nvarchar(max)",
                nullable: true);

            // ==========================================
            // 🏥 إنشاء جدول DrugInteractions
            // ==========================================
            migrationBuilder.CreateTable(
                name: "DrugInteractions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ClinicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Drug1 = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Drug2 = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Severity = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    InteractionDescription = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Recommendation = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    EvidenceSource = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastUpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DrugInteractions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DrugInteractions_Clinics_ClinicId",
                        column: x => x.ClinicId,
                        principalTable: "Clinics",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DrugInteractions_Unique",
                table: "DrugInteractions",
                columns: new[] { "Drug1", "Drug2", "ClinicId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DrugInteractions_ClinicId",
                table: "DrugInteractions",
                column: "ClinicId");

            migrationBuilder.CreateIndex(
                name: "IX_DrugInteractions_IsActive",
                table: "DrugInteractions",
                column: "IsActive");

            // ==========================================
            // 🏥 إنشاء جدول PatientRiskProfiles
            // ==========================================
            migrationBuilder.CreateTable(
                name: "PatientRiskProfiles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PatientId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    HasDiabetes = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    HasHypertension = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    HasHeartDisease = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    HasKidneyDisease = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    HasLiverDisease = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    HasAsthma = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    HasThyroidDisease = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    HasAutoimmune = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    OnImmunosuppressants = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    OnAnticoagulants = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    IsPregnant = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    IsBreastfeeding = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    IsPostSurgery = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    RiskScore = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    SpecialNotes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastUpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PatientRiskProfiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PatientRiskProfiles_Patients_PatientId",
                        column: x => x.PatientId,
                        principalTable: "Patients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PatientRiskProfile_PatientId_Unique",
                table: "PatientRiskProfiles",
                column: "PatientId",
                unique: true);

            // ==========================================
            // 🏥 إنشاء جدول MedicationTemplates
            // ==========================================
            migrationBuilder.CreateTable(
                name: "MedicationTemplates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ClinicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Specialty = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    MedicinesJson = table.Column<string>(type: "nvarchar(max)", nullable: false, defaultValue: "[]"),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    UsageCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    Version = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastUsedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    LastUpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MedicationTemplates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MedicationTemplates_Clinics_ClinicId",
                        column: x => x.ClinicId,
                        principalTable: "Clinics",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MedicationTemplates_ClinicId",
                table: "MedicationTemplates",
                column: "ClinicId");

            migrationBuilder.CreateIndex(
                name: "IX_MedicationTemplates_IsActive",
                table: "MedicationTemplates",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_MedicationTemplates_Specialty",
                table: "MedicationTemplates",
                column: "Specialty");

            // ==========================================
            // 🏥 إنشاء جدول ClinicalAlerts
            // ==========================================
            migrationBuilder.CreateTable(
                name: "ClinicalAlerts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ClinicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PatientId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    PrescriptionId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    AlertType = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    Priority = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Message = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Recommendation = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsResolved = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    ResolvedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ResolutionNotes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastUpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClinicalAlerts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ClinicalAlerts_Clinics_ClinicId",
                        column: x => x.ClinicId,
                        principalTable: "Clinics",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ClinicalAlerts_Patients_PatientId",
                        column: x => x.PatientId,
                        principalTable: "Patients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ClinicalAlerts_Prescriptions_PrescriptionId",
                        column: x => x.PrescriptionId,
                        principalTable: "Prescriptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalAlerts_ClinicId",
                table: "ClinicalAlerts",
                column: "ClinicId");

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalAlerts_PatientId",
                table: "ClinicalAlerts",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalAlerts_PrescriptionId",
                table: "ClinicalAlerts",
                column: "PrescriptionId");

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalAlerts_IsResolved",
                table: "ClinicalAlerts",
                column: "IsResolved");

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalAlerts_Priority",
                table: "ClinicalAlerts",
                column: "Priority");

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalAlerts_CreatedAt",
                table: "ClinicalAlerts",
                column: "CreatedAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // حذف الجداول الجديدة
            migrationBuilder.DropTable(
                name: "ClinicalAlerts");

            migrationBuilder.DropTable(
                name: "MedicationTemplates");

            migrationBuilder.DropTable(
                name: "PatientRiskProfiles");

            migrationBuilder.DropTable(
                name: "DrugInteractions");

            // إزالة الأعمدة من PrescriptionMedicines
            migrationBuilder.DropColumn(
                name: "RouteOfAdministration",
                table: "PrescriptionMedicines");

            migrationBuilder.DropColumn(
                name: "Indication",
                table: "PrescriptionMedicines");

            migrationBuilder.DropColumn(
                name: "WarningsAndContraindications",
                table: "PrescriptionMedicines");

            migrationBuilder.DropColumn(
                name: "DrugInteractionRisk",
                table: "PrescriptionMedicines");

            // إزالة الأعمدة من Patients
            migrationBuilder.DropColumn(
                name: "Allergies",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "ChronicDiseases",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "BloodGroup",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "Height",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "IsPregnant",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "AgeCategory",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "MedicationHistoryJson",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "CurrentMedicationsJson",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "PreexistingConditionsJson",
                table: "Patients");
        }
    }
}
