using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Rachita.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixSchemaSync : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Update Prescriptions table - Populating ClinicId from Patients to avoid FK conflicts
            migrationBuilder.Sql(
                "IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Prescriptions]') AND name = 'ClinicId') " +
                "BEGIN " +
                "  ALTER TABLE [Prescriptions] ADD [ClinicId] uniqueidentifier NULL; " +
                "END");

            migrationBuilder.Sql(
                "UPDATE R SET R.ClinicId = P.ClinicId " +
                "FROM [Prescriptions] R " +
                "JOIN [Patients] P ON R.PatientId = P.Id " +
                "WHERE R.ClinicId IS NULL");

            migrationBuilder.Sql(
                "DECLARE @DefaultClinicId uniqueidentifier; " +
                "SELECT TOP 1 @DefaultClinicId = Id FROM [Clinics]; " +
                "IF @DefaultClinicId IS NOT NULL " +
                "BEGIN " +
                "  UPDATE [Prescriptions] SET [ClinicId] = @DefaultClinicId WHERE [ClinicId] IS NULL; " +
                "END");

            migrationBuilder.Sql(
                "IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Prescriptions]') AND name = 'ClinicId' AND is_nullable = 1) " +
                "BEGIN " +
                "  ALTER TABLE [Prescriptions] ALTER COLUMN [ClinicId] uniqueidentifier NOT NULL; " +
                "END");

            // Update PrescriptionMedicines table
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[PrescriptionMedicines]') AND name = 'DrugInteractionRisk') " +
                                 "ALTER TABLE [PrescriptionMedicines] ADD [DrugInteractionRisk] nvarchar(max) NULL");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[PrescriptionMedicines]') AND name = 'Indication') " +
                                 "ALTER TABLE [PrescriptionMedicines] ADD [Indication] nvarchar(max) NULL");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[PrescriptionMedicines]') AND name = 'RouteOfAdministration') " +
                                 "ALTER TABLE [PrescriptionMedicines] ADD [RouteOfAdministration] nvarchar(max) NULL");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[PrescriptionMedicines]') AND name = 'WarningsAndContraindications') " +
                                 "ALTER TABLE [PrescriptionMedicines] ADD [WarningsAndContraindications] nvarchar(max) NULL");

            // Update Patients table
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'AgeCategory') " +
                                 "ALTER TABLE [Patients] ADD [AgeCategory] int NOT NULL DEFAULT 0");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'Allergies') " +
                                 "ALTER TABLE [Patients] ADD [Allergies] nvarchar(max) NULL");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'BloodGroup') " +
                                 "ALTER TABLE [Patients] ADD [BloodGroup] nvarchar(max) NULL");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'ChronicDiseases') " +
                                 "ALTER TABLE [Patients] ADD [ChronicDiseases] nvarchar(max) NULL");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'CurrentMedicationsJson') " +
                                 "ALTER TABLE [Patients] ADD [CurrentMedicationsJson] nvarchar(max) NOT NULL DEFAULT ''");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'Height') " +
                                 "ALTER TABLE [Patients] ADD [Height] float NULL");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'IsPregnant') " +
                                 "ALTER TABLE [Patients] ADD [IsPregnant] bit NOT NULL DEFAULT 0");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'MedicationHistoryJson') " +
                                 "ALTER TABLE [Patients] ADD [MedicationHistoryJson] nvarchar(max) NOT NULL DEFAULT ''");
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'PreexistingConditionsJson') " +
                                 "ALTER TABLE [Patients] ADD [PreexistingConditionsJson] nvarchar(max) NOT NULL DEFAULT ''");

            // Create New Tables if missing
            migrationBuilder.Sql("IF OBJECT_ID(N'[ClinicalAlerts]', 'U') IS NULL " +
                "CREATE TABLE [ClinicalAlerts] (" +
                "[Id] [uniqueidentifier] NOT NULL, " +
                "[ClinicId] [uniqueidentifier] NOT NULL, " +
                "[PatientId] [uniqueidentifier] NULL, " +
                "[PrescriptionId] [uniqueidentifier] NULL, " +
                "[AlertType] [int] NOT NULL, " +
                "[Priority] [int] NOT NULL, " +
                "[Title] [nvarchar](max) NOT NULL, " +
                "[Message] [nvarchar](max) NOT NULL, " +
                "[Recommendation] [nvarchar](max) NULL, " +
                "[IsResolved] [bit] NOT NULL, " +
                "[ResolvedAt] [datetime2](7) NULL, " +
                "[ResolutionNotes] [nvarchar](max) NULL, " +
                "[CreatedAt] [datetime2](7) NOT NULL, " +
                "[LastUpdatedAt] [datetime2](7) NOT NULL, " +
                "CONSTRAINT [PK_ClinicalAlerts] PRIMARY KEY ([Id]))");

            migrationBuilder.Sql("IF OBJECT_ID(N'[DoctorProfiles]', 'U') IS NULL " +
                "CREATE TABLE [DoctorProfiles] (" +
                "[Id] [int] IDENTITY(1,1) NOT NULL, " +
                "[ClinicId] [uniqueidentifier] NOT NULL, " +
                "[Name] [nvarchar](max) NOT NULL, " +
                "[NameEn] [nvarchar](max) NULL, " +
                "[Specialty] [nvarchar](max) NOT NULL, " +
                "[SpecialtyEn] [nvarchar](max) NULL, " +
                "[SubSpecialty] [nvarchar](max) NULL, " +
                "[SubSpecialtyEn] [nvarchar](max) NULL, " +
                "[ClinicName] [nvarchar](max) NOT NULL, " +
                "[LicenseNumber] [nvarchar](max) NULL, " +
                "[Credentials] [nvarchar](max) NULL, " +
                "[CredentialsEn] [nvarchar](max) NULL, " +
                "[Address] [nvarchar](max) NULL, " +
                "[Phone] [nvarchar](max) NULL, " +
                "[WorkingHoursFrom] [nvarchar](max) NULL, " +
                "[WorkingHoursTo] [nvarchar](max) NULL, " +
                "[LogoPath] [nvarchar](max) NULL, " +
                "[SignaturePath] [nvarchar](max) NULL, " +
                "[PhotoPath] [nvarchar](max) NULL, " +
                "[Bio] [nvarchar](max) NULL, " +
                "[BioEn] [nvarchar](max) NULL, " +
                "[CreatedAt] [datetime2](7) NOT NULL, " +
                "[UpdatedAt] [datetime2](7) NOT NULL, " +
                "CONSTRAINT [PK_DoctorProfiles] PRIMARY KEY ([Id]))");

            migrationBuilder.Sql("IF OBJECT_ID(N'[DrugInteractions]', 'U') IS NULL " +
                "CREATE TABLE [DrugInteractions] (" +
                "[Id] [uniqueidentifier] NOT NULL, " +
                "[ClinicId] [uniqueidentifier] NOT NULL, " +
                "[Drug1] [nvarchar](450) NOT NULL, " +
                "[Drug2] [nvarchar](450) NOT NULL, " +
                "[Severity] [int] NOT NULL, " +
                "[InteractionDescription] [nvarchar](max) NOT NULL, " +
                "[Recommendation] [nvarchar](max) NULL, " +
                "[EvidenceSource] [nvarchar](max) NULL, " +
                "[IsActive] [bit] NOT NULL, " +
                "[CreatedAt] [datetime2](7) NOT NULL, " +
                "[LastUpdatedAt] [datetime2](7) NOT NULL, " +
                "CONSTRAINT [PK_DrugInteractions] PRIMARY KEY ([Id]))");

            migrationBuilder.Sql("IF OBJECT_ID(N'[MedicationTemplates]', 'U') IS NULL " +
                "CREATE TABLE [MedicationTemplates] (" +
                "[Id] [uniqueidentifier] NOT NULL, " +
                "[ClinicId] [uniqueidentifier] NOT NULL, " +
                "[Name] [nvarchar](max) NOT NULL, " +
                "[Description] [nvarchar](max) NULL, " +
                "[Specialty] [nvarchar](450) NULL, " +
                "[MedicinesJson] [nvarchar](max) NOT NULL, " +
                "[IsActive] [bit] NOT NULL, " +
                "[UsageCount] [int] NOT NULL, " +
                "[Version] [int] NOT NULL, " +
                "[CreatedAt] [datetime2](7) NOT NULL, " +
                "[LastUsedAt] [datetime2](7) NULL, " +
                "[LastUpdatedAt] [datetime2](7) NOT NULL, " +
                "CONSTRAINT [PK_MedicationTemplates] PRIMARY KEY ([Id]))");

            migrationBuilder.Sql("IF OBJECT_ID(N'[PatientRiskProfiles]', 'U') IS NULL " +
                "CREATE TABLE [PatientRiskProfiles] (" +
                "[Id] [uniqueidentifier] NOT NULL, " +
                "[PatientId] [uniqueidentifier] NOT NULL, " +
                "[HasDiabetes] [bit] NOT NULL, " +
                "[HasHypertension] [bit] NOT NULL, " +
                "[HasHeartDisease] [bit] NOT NULL, " +
                "[HasKidneyDisease] [bit] NOT NULL, " +
                "[HasLiverDisease] [bit] NOT NULL, " +
                "[HasAsthma] [bit] NOT NULL, " +
                "[HasThyroidDisease] [bit] NOT NULL, " +
                "[HasAutoimmune] [bit] NOT NULL, " +
                "[OnImmunosuppressants] [bit] NOT NULL, " +
                "[OnAnticoagulants] [bit] NOT NULL, " +
                "[IsPregnant] [bit] NOT NULL, " +
                "[IsBreastfeeding] [bit] NOT NULL, " +
                "[IsPostSurgery] [bit] NOT NULL, " +
                "[RiskScore] [int] NOT NULL, " +
                "[LastRiskAssessmentAt] [datetime2](7) NOT NULL, " +
                "[SpecialNotes] [nvarchar](max) NULL, " +
                "[CreatedAt] [datetime2](7) NOT NULL, " +
                "[LastUpdatedAt] [datetime2](7) NOT NULL, " +
                "CONSTRAINT [PK_PatientRiskProfiles] PRIMARY KEY ([Id]))");

            // Add Foreign Keys if missing (Safe additions)
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ClinicalAlerts_Clinics_ClinicId') " +
                "ALTER TABLE [ClinicalAlerts] ADD CONSTRAINT [FK_ClinicalAlerts_Clinics_ClinicId] FOREIGN KEY ([ClinicId]) REFERENCES [Clinics] ([Id]) ON DELETE NO ACTION");
            
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Prescriptions_Clinics_ClinicId') " +
                "ALTER TABLE [Prescriptions] ADD CONSTRAINT [FK_Prescriptions_Clinics_ClinicId] FOREIGN KEY ([ClinicId]) REFERENCES [Clinics] ([Id]) ON DELETE NO ACTION");

            // Add Indexes if missing
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ClinicalAlerts_ClinicId' AND object_id = OBJECT_ID('ClinicalAlerts')) " +
                "CREATE INDEX [IX_ClinicalAlerts_ClinicId] ON [ClinicalAlerts] ([ClinicId])");
            
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ClinicalAlerts_CreatedAt' AND object_id = OBJECT_ID('ClinicalAlerts')) " +
                "CREATE INDEX [IX_ClinicalAlerts_CreatedAt] ON [ClinicalAlerts] ([CreatedAt])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ClinicalAlerts_IsResolved' AND object_id = OBJECT_ID('ClinicalAlerts')) " +
                "CREATE INDEX [IX_ClinicalAlerts_IsResolved] ON [ClinicalAlerts] ([IsResolved])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ClinicalAlerts_PatientId' AND object_id = OBJECT_ID('ClinicalAlerts')) " +
                "CREATE INDEX [IX_ClinicalAlerts_PatientId] ON [ClinicalAlerts] ([PatientId])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ClinicalAlerts_PrescriptionId' AND object_id = OBJECT_ID('ClinicalAlerts')) " +
                "CREATE INDEX [IX_ClinicalAlerts_PrescriptionId] ON [ClinicalAlerts] ([PrescriptionId])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ClinicalAlerts_Priority' AND object_id = OBJECT_ID('ClinicalAlerts')) " +
                "CREATE INDEX [IX_ClinicalAlerts_Priority] ON [ClinicalAlerts] ([Priority])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DoctorProfiles_ClinicId' AND object_id = OBJECT_ID('DoctorProfiles')) " +
                "CREATE UNIQUE INDEX [IX_DoctorProfiles_ClinicId] ON [DoctorProfiles] ([ClinicId])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DrugInteraction_Unique' AND object_id = OBJECT_ID('DrugInteractions')) " +
                "CREATE UNIQUE INDEX [IX_DrugInteraction_Unique] ON [DrugInteractions] ([Drug1], [Drug2], [ClinicId])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DrugInteractions_ClinicId' AND object_id = OBJECT_ID('DrugInteractions')) " +
                "CREATE INDEX [IX_DrugInteractions_ClinicId] ON [DrugInteractions] ([ClinicId])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DrugInteractions_Drug1_Drug2' AND object_id = OBJECT_ID('DrugInteractions')) " +
                "CREATE INDEX [IX_DrugInteractions_Drug1_Drug2] ON [DrugInteractions] ([Drug1], [Drug2])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DrugInteractions_IsActive' AND object_id = OBJECT_ID('DrugInteractions')) " +
                "CREATE INDEX [IX_DrugInteractions_IsActive] ON [DrugInteractions] ([IsActive])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MedicationTemplates_ClinicId' AND object_id = OBJECT_ID('MedicationTemplates')) " +
                "CREATE INDEX [IX_MedicationTemplates_ClinicId] ON [MedicationTemplates] ([ClinicId])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MedicationTemplates_IsActive' AND object_id = OBJECT_ID('MedicationTemplates')) " +
                "CREATE INDEX [IX_MedicationTemplates_IsActive] ON [MedicationTemplates] ([IsActive])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MedicationTemplates_Specialty' AND object_id = OBJECT_ID('MedicationTemplates')) " +
                "CREATE INDEX [IX_MedicationTemplates_Specialty] ON [MedicationTemplates] ([Specialty])");
                
            migrationBuilder.Sql("IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PatientRiskProfile_PatientId_Unique' AND object_id = OBJECT_ID('PatientRiskProfiles')) " +
                "CREATE UNIQUE INDEX [IX_PatientRiskProfile_PatientId_Unique] ON [PatientRiskProfiles] ([PatientId])");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ClinicalAlerts");

            migrationBuilder.DropTable(
                name: "DoctorProfiles");

            migrationBuilder.DropTable(
                name: "DrugInteractions");

            migrationBuilder.DropTable(
                name: "MedicationTemplates");

            migrationBuilder.DropTable(
                name: "PatientRiskProfiles");

            migrationBuilder.DropColumn(
                name: "ClinicId",
                table: "Prescriptions");

            migrationBuilder.DropColumn(
                name: "DrugInteractionRisk",
                table: "PrescriptionMedicines");

            migrationBuilder.DropColumn(
                name: "Indication",
                table: "PrescriptionMedicines");

            migrationBuilder.DropColumn(
                name: "RouteOfAdministration",
                table: "PrescriptionMedicines");

            migrationBuilder.DropColumn(
                name: "WarningsAndContraindications",
                table: "PrescriptionMedicines");

            migrationBuilder.DropColumn(
                name: "AgeCategory",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "Allergies",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "BloodGroup",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "ChronicDiseases",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "CurrentMedicationsJson",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "Height",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "IsPregnant",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "MedicationHistoryJson",
                table: "Patients");

            migrationBuilder.DropColumn(
                name: "PreexistingConditionsJson",
                table: "Patients");
        }
    }
}
