class DBConstants {
  static const int version = 23; // إضافة جداول Audit Trail و Medication Reminders
  static const String databaseName = 'clinic_smart_v2.db';

  // Tables - Original
  static const String tableDoctor = 'doctor_profile';
  static const String tablePatients = 'patients';
  static const String tablePrescriptions = 'prescriptions';
  static const String tablePrescriptionMedicines = 'prescription_medicines';
  static const String tableMedicines = 'medicines';
  static const String tableMedicinesFts = 'medicines_fts';
  static const String tableSyncLog = 'sync_log';
  static const String tableVitals = 'patient_vitals';
  static const String tableDoctorPatterns = 'doctor_patterns';

  // Tables - 🏥 جديدة للذكاء الطبي
  static const String tableDrugInteractions = 'drug_interactions';
  static const String tablePatientRiskProfiles = 'patient_risk_profiles';
  static const String tableMedicationTemplates = 'medication_templates';
  static const String tableClinicalAlerts = 'clinical_alerts';

  // Tables - 🔐 Audit & Reminders
  static const String tableAuditLog = 'audit_log';
  static const String tableMedicationReminders = 'medication_reminders';
}
