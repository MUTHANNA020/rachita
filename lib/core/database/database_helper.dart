import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'database_constants.dart';
import '../../features/medicine/data/sources/medicine_library_seeder.dart';
import '../../features/medicine/data/models/medicine_model.dart';
import '../../features/prescription/data/sources/drug_interaction_seeder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  String? _currentDbName;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // تحديد اسم قاعدة البيانات بناءً على هوية العيادة أو المستخدم المسجل
    final prefs = await SharedPreferences.getInstance();
    final clinicId = prefs.getString('clinic_id');

    String dbName = DBConstants.databaseName; // Default value (fallback)
    if (clinicId != null && clinicId.isNotEmpty) {
      // إزالة الأحرف غير المسموح بها في أسماء الملفات إن وجدت
      final safeClinicId = clinicId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      dbName = 'clinic_smart_$safeClinicId.db';
    }

    _currentDbName = dbName;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      path = filePath;
    } else if (Platform.environment.containsKey('FLUTTER_TEST')) {
      path = inMemoryDatabasePath; // لتجنب أخطاء مسارات الملفات أثناء تشغيل الاختبارات
    } else {
      final dbPath = await getApplicationDocumentsDirectory();
      path = join(dbPath.path, filePath);
    }

    final db = await openDatabase(
      path,
      version: DBConstants.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    // لضمان وجود الأعمدة المطلوبة للمزامنة دوماً قبل بدء العمل
    await ensureSchemaConsistency(db);

    // Seed medicines if library is empty (High-Precision Clinical Intelligence Upgrade)
    await _seedInitialMedicines(db);

    // Seed drug interactions (The Real Medical Brain)
    await _seedDrugInteractions(db);

    return db;
  }

  Future<void> _seedInitialMedicines(Database db) async {
    final count = Sqflite.firstIntValue(await db
        .rawQuery('SELECT COUNT(*) FROM ${DBConstants.tableMedicines}'));
    if (count != null && count < 10) {
      final batch = db.batch();
      final medicines = MedicineLibrarySeeder.getMedicines();
      for (var med in medicines) {
        final model = MedicineModel.fromEntity(med);
        batch.insert(DBConstants.tableMedicines, model.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _seedDrugInteractions(Database db) async {
    final count = Sqflite.firstIntValue(await db
        .rawQuery('SELECT COUNT(*) FROM ${DBConstants.tableDrugInteractions}'));
    if (count != null && count == 0) {
      final batch = db.batch();
      final interactions = DrugInteractionSeeder.getInteractions();
      for (var interaction in interactions) {
        batch.insert(DBConstants.tableDrugInteractions, interaction,
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    }
  }

  Future _createDB(Database db, int version) async {
    // DOCTOR PROFILE
    await db.execute('''
      CREATE TABLE ${DBConstants.tableDoctor} (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        name_en TEXT,
        specialty TEXT NOT NULL,
        specialty_en TEXT,
        sub_specialty TEXT,
        sub_specialty_en TEXT,
        clinic_name TEXT NOT NULL,
        license_number TEXT,
        credentials TEXT,
        credentials_en TEXT,
        address TEXT,
        phone TEXT,
        working_hours_from TEXT,
        working_hours_to TEXT,
        logo_path TEXT,
        signature_path TEXT,
        photo_path TEXT,
        bio TEXT,
        bio_en TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        follow_up_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // PATIENTS
    await db.execute('''
      CREATE TABLE ${DBConstants.tablePatients} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE,
        name TEXT NOT NULL,
        age INTEGER,
        gender TEXT CHECK(gender IN ('male','female')),
        phone TEXT,
        identity_number TEXT,
        clinic_id TEXT,
        notes TEXT,
        visit_count INTEGER DEFAULT 0,
        last_visit TEXT,
        allergies TEXT,
        chronic_diseases TEXT,
        blood_group TEXT,
        height REAL,
        is_pregnant INTEGER DEFAULT 0,
        age_category INTEGER DEFAULT 2,
        medication_history_json TEXT DEFAULT '[]',
        current_medications_json TEXT DEFAULT '[]',
        preexisting_conditions_json TEXT DEFAULT '[]',
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        follow_up_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // PRESCRIPTIONS
    await db.execute('''
      CREATE TABLE ${DBConstants.tablePrescriptions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE,
        patient_id INTEGER NOT NULL,
        doctor_id TEXT,
        diagnosis TEXT NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        weight REAL,
        systolic INTEGER,
        diastolic INTEGER,
        pulse INTEGER,
        sugar REAL,
        temperature REAL,
        height REAL,
        head_circ REAL,
        extra_vitals TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        follow_up_date TEXT,
        attachments TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(patient_id) REFERENCES ${DBConstants.tablePatients}(id) ON DELETE CASCADE
      )
    ''');

    // PRESCRIPTION MEDICINES
    await db.execute('''
      CREATE TABLE ${DBConstants.tablePrescriptionMedicines} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE,
        prescription_id INTEGER NOT NULL,
        medicine_name TEXT NOT NULL,
        medicine_name_en TEXT,
        dosage TEXT NOT NULL,
        dosage_unit TEXT,
        frequency TEXT NOT NULL,
        frequency_detailed TEXT,
        duration TEXT NOT NULL,
        duration_unit TEXT,
        route_of_admin TEXT,
        route_of_administration TEXT,
        total_units INTEGER,
        instructions TEXT,
        indication TEXT,
        warnings_and_contraindications TEXT,
        drug_interaction_risk TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        follow_up_date TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(prescription_id) REFERENCES ${DBConstants.tablePrescriptions}(id) ON DELETE CASCADE
      )
    ''');

    // MEDICINES
    await db.execute('''
      CREATE TABLE ${DBConstants.tableMedicines} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        category TEXT,
        common_dose TEXT,
        common_freq TEXT,
        use_count INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // SYNC LOG
    await db.execute('''
      CREATE TABLE ${DBConstants.tableSyncLog} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        action TEXT CHECK(action IN ('insert','update','delete')),
        synced_at TEXT,
        error TEXT
      )
    ''');

    // MEDICINES FTS
    // MEDICINES FTS
    // Using a simple virtual table without 'content' for maximum reliability across Web/Mobile
    const ftsModule = kIsWeb ? 'fts5' : 'fts4';
    try {
      await db.execute(
          'CREATE VIRTUAL TABLE ${DBConstants.tableMedicinesFts} USING $ftsModule(name_ar, name_en)');
    } catch (_) {
      // Final fallback if the preferred module is missing
      await db.execute(
          'CREATE VIRTUAL TABLE ${DBConstants.tableMedicinesFts} USING fts4(name_ar, name_en)');
    }

    // VITALS
    await db.execute('''
      CREATE TABLE ${DBConstants.tableVitals} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE,
        patient_id INTEGER NOT NULL,
        prescription_id INTEGER,
        weight REAL,
        systolic INTEGER,
        diastolic INTEGER,
        pulse INTEGER,
        sugar REAL,
        temperature REAL,
        height REAL,
        head_circ REAL,
        extra_vitals TEXT,
        date TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        follow_up_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(patient_id) REFERENCES ${DBConstants.tablePatients}(id) ON DELETE CASCADE
      )
    ''');

    // DOCTOR PATTERNS (AI LAYER)
    await db.execute('''
      CREATE TABLE ${DBConstants.tableDoctorPatterns} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diagnosis TEXT NOT NULL,
        medicine_name TEXT NOT NULL,
        medicine_name_en TEXT,
        dosage TEXT,
        frequency TEXT,
        duration TEXT,
        route_of_admin TEXT,
        use_count INTEGER DEFAULT 1,
        last_used TEXT NOT NULL,
        UNIQUE(diagnosis, medicine_name) ON CONFLICT REPLACE
      )
    ''');

    // SYNC TRIGGERS for FTS
    await db.execute('''
      CREATE TRIGGER medicines_ai AFTER INSERT ON ${DBConstants.tableMedicines} BEGIN
        INSERT INTO ${DBConstants.tableMedicinesFts}(rowid, name_ar, name_en) VALUES (new.id, new.name_ar, new.name_en);
      END
    ''');
    await db.execute('''
      CREATE TRIGGER medicines_ad AFTER DELETE ON ${DBConstants.tableMedicines} BEGIN
        DELETE FROM ${DBConstants.tableMedicinesFts} WHERE rowid = old.id;
      END
    ''');
    await db.execute('''
      CREATE TRIGGER medicines_au AFTER UPDATE ON ${DBConstants.tableMedicines} BEGIN
        DELETE FROM ${DBConstants.tableMedicinesFts} WHERE rowid = old.id;
        INSERT INTO ${DBConstants.tableMedicinesFts}(rowid, name_ar, name_en) VALUES (new.id, new.name_ar, new.name_en);
      END
    ''');

    // 🏥 DRUG INTERACTIONS - جدول تفاعلات الأدوية
    await db.execute('''
      CREATE TABLE ${DBConstants.tableDrugInteractions} (
        id TEXT PRIMARY KEY,
        clinic_id TEXT NOT NULL,
        drug1 TEXT NOT NULL,
        drug2 TEXT NOT NULL,
        severity INTEGER DEFAULT 0,
        interaction_description TEXT NOT NULL,
        recommendation TEXT,
        evidence_source TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        last_updated_at TEXT NOT NULL
      )
    ''');

    // 🏥 PATIENT RISK PROFILES - ملف تقييم مخاطر المريض
    await db.execute('''
      CREATE TABLE ${DBConstants.tablePatientRiskProfiles} (
        id TEXT PRIMARY KEY,
        patient_id INTEGER NOT NULL UNIQUE,
        has_diabetes INTEGER DEFAULT 0,
        has_hypertension INTEGER DEFAULT 0,
        has_heart_disease INTEGER DEFAULT 0,
        has_kidney_disease INTEGER DEFAULT 0,
        has_liver_disease INTEGER DEFAULT 0,
        has_asthma INTEGER DEFAULT 0,
        has_thyroid_disease INTEGER DEFAULT 0,
        has_autoimmune INTEGER DEFAULT 0,
        on_immunosuppressants INTEGER DEFAULT 0,
        on_anticoagulants INTEGER DEFAULT 0,
        is_pregnant INTEGER DEFAULT 0,
        is_breastfeeding INTEGER DEFAULT 0,
        is_post_surgery INTEGER DEFAULT 0,
        risk_score INTEGER DEFAULT 0,
        special_notes TEXT,
        created_at TEXT NOT NULL,
        last_updated_at TEXT NOT NULL,
        FOREIGN KEY(patient_id) REFERENCES ${DBConstants.tablePatients}(id) ON DELETE CASCADE
      )
    ''');

    // 🏥 MEDICATION TEMPLATES - نماذج العلاج المحفوظة
    await db.execute('''
      CREATE TABLE ${DBConstants.tableMedicationTemplates} (
        id TEXT PRIMARY KEY,
        clinic_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        specialty TEXT,
        medicines_json TEXT DEFAULT '[]',
        is_active INTEGER DEFAULT 1,
        usage_count INTEGER DEFAULT 0,
        version INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        last_used_at TEXT,
        last_updated_at TEXT NOT NULL
      )
    ''');

    // 🏥 CLINICAL ALERTS - التنبيهات السريرية
    await db.execute('''
      CREATE TABLE ${DBConstants.tableClinicalAlerts} (
        id TEXT PRIMARY KEY,
        clinic_id TEXT NOT NULL,
        patient_id TEXT,
        prescription_id TEXT,
        alert_type INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 1,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        recommendation TEXT,
        is_resolved INTEGER DEFAULT 0,
        resolved_at TEXT,
        resolution_notes TEXT,
        created_at TEXT NOT NULL,
        last_updated_at TEXT NOT NULL
      )
    ''');

    // INDEXES for performance
    await db.execute(
        'CREATE INDEX idx_patients_name ON ${DBConstants.tablePatients}(name)');
    await db.execute(
        'CREATE INDEX idx_prescriptions_patient_id ON ${DBConstants.tablePrescriptions}(patient_id)');
    await db.execute(
        'CREATE INDEX idx_prescription_medicines_prescription_id ON ${DBConstants.tablePrescriptionMedicines}(prescription_id)');
    await db.execute(
        'CREATE INDEX idx_medicines_name_ar ON ${DBConstants.tableMedicines}(name_ar)');
    await db.execute(
        'CREATE INDEX idx_vitals_patient_id ON ${DBConstants.tableVitals}(patient_id)');
    await db.execute(
        'CREATE INDEX idx_doctor_patterns_diagnosis ON ${DBConstants.tableDoctorPatterns}(diagnosis)');

    // 🏥 Indexes للجداول الجديدة
    await db.execute(
        'CREATE UNIQUE INDEX idx_drug_interactions_unique ON ${DBConstants.tableDrugInteractions}(drug1, drug2, clinic_id)');
    await db.execute(
        'CREATE INDEX idx_drug_interactions_clinic ON ${DBConstants.tableDrugInteractions}(clinic_id)');
    await db.execute(
        'CREATE INDEX idx_patient_risk_profiles_patient ON ${DBConstants.tablePatientRiskProfiles}(patient_id)');
    await db.execute(
        'CREATE INDEX idx_medication_templates_clinic ON ${DBConstants.tableMedicationTemplates}(clinic_id)');
    await db.execute(
        'CREATE INDEX idx_medication_templates_active ON ${DBConstants.tableMedicationTemplates}(is_active)');
    await db.execute(
        'CREATE INDEX idx_clinical_alerts_clinic ON ${DBConstants.tableClinicalAlerts}(clinic_id)');
    await db.execute(
        'CREATE INDEX idx_clinical_alerts_patient ON ${DBConstants.tableClinicalAlerts}(patient_id)');
    await db.execute(
        'CREATE INDEX idx_clinical_alerts_priority ON ${DBConstants.tableClinicalAlerts}(priority)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePatients} ADD COLUMN visit_count INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePatients} ADD COLUMN last_visit TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePatients} ADD COLUMN is_synced INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePatients} ADD COLUMN updated_at TEXT DEFAULT ""');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN license_number TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptionMedicines} ADD COLUMN route_of_admin TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptionMedicines} ADD COLUMN total_units INTEGER');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptions} ADD COLUMN updated_at TEXT DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptions} ADD COLUMN is_deleted INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptions} ADD COLUMN doctor_id TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePatients} ADD COLUMN identity_number TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePatients} ADD COLUMN clinic_id TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptionMedicines} ADD COLUMN is_synced INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptionMedicines} ADD COLUMN updated_at TEXT DEFAULT ""');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN name_en TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN specialty_en TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN credentials_en TEXT');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
            'CREATE INDEX idx_patients_name ON ${DBConstants.tablePatients}(name)');
      } catch (_) {}
      try {
        await db.execute(
            'CREATE INDEX idx_prescriptions_patient_id ON ${DBConstants.tablePrescriptions}(patient_id)');
      } catch (_) {}
      try {
        await db.execute(
            'CREATE INDEX idx_prescription_medicines_prescription_id ON ${DBConstants.tablePrescriptionMedicines}(prescription_id)');
      } catch (_) {}
      try {
        await db.execute(
            'CREATE INDEX idx_medicines_name_ar ON ${DBConstants.tableMedicines}(name_ar)');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN photo_path TEXT');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN bio TEXT');
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN bio_en TEXT');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptions} ADD COLUMN attachments TEXT');
      } catch (_) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptionMedicines} ADD COLUMN medicine_name_en TEXT');
      } catch (_) {}
    }
    if (oldVersion < 11) {
      try {
        await db.execute('''
          CREATE TABLE ${DBConstants.tableVitals} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_id INTEGER NOT NULL,
            prescription_id INTEGER,
            weight REAL,
            systolic INTEGER,
            diastolic INTEGER,
            pulse INTEGER,
            sugar REAL,
            temperature REAL,
            date TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY(patient_id) REFERENCES ${DBConstants.tablePatients}(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_vitals_patient_id ON ${DBConstants.tableVitals}(patient_id)');
      } catch (_) {}
    }
    if (oldVersion < 12) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN sub_specialty TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableDoctor} ADD COLUMN sub_specialty_en TEXT');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE ${DBConstants.tableDoctorPatterns} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            diagnosis TEXT NOT NULL,
            medicine_name TEXT NOT NULL,
            medicine_name_en TEXT,
            dosage TEXT,
            frequency TEXT,
            duration TEXT,
            route_of_admin TEXT,
            use_count INTEGER DEFAULT 1,
            last_used TEXT NOT NULL,
            UNIQUE(diagnosis, medicine_name) ON CONFLICT REPLACE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_doctor_patterns_diagnosis ON ${DBConstants.tableDoctorPatterns}(diagnosis)');
      } catch (_) {}
    }
    if (oldVersion < 13) {
      // Migrate FTS5 to FTS4
      try {
        await db
            .execute('DROP TABLE IF EXISTS ${DBConstants.tableMedicinesFts}');
        // Migrate to a resilient FTS implementation
        const ftsModule = kIsWeb ? 'fts5' : 'fts4';
        try {
          await db.execute(
              'CREATE VIRTUAL TABLE ${DBConstants.tableMedicinesFts} USING $ftsModule(name_ar, name_en)');
        } catch (_) {
          await db.execute(
              'CREATE VIRTUAL TABLE ${DBConstants.tableMedicinesFts} USING fts4(name_ar, name_en)');
        }

        // Re-populate data
        await db.execute(
            'INSERT INTO ${DBConstants.tableMedicinesFts}(rowid, name_ar, name_en) SELECT id, name_ar, name_en FROM ${DBConstants.tableMedicines}');

        // Update triggers
        await db.execute('DROP TRIGGER IF EXISTS medicines_ai');
        await db.execute('DROP TRIGGER IF EXISTS medicines_ad');
        await db.execute('DROP TRIGGER IF EXISTS medicines_au');

        await db.execute('''
          CREATE TRIGGER medicines_ai AFTER INSERT ON ${DBConstants.tableMedicines} BEGIN
            INSERT INTO ${DBConstants.tableMedicinesFts}(rowid, name_ar, name_en) VALUES (new.id, new.name_ar, new.name_en);
          END
        ''');
        await db.execute('''
          CREATE TRIGGER medicines_ad AFTER DELETE ON ${DBConstants.tableMedicines} BEGIN
            DELETE FROM ${DBConstants.tableMedicinesFts} WHERE rowid = old.id;
          END
        ''');
        await db.execute('''
          CREATE TRIGGER medicines_au AFTER UPDATE ON ${DBConstants.tableMedicines} BEGIN
            DELETE FROM ${DBConstants.tableMedicinesFts} WHERE rowid = old.id;
            INSERT INTO ${DBConstants.tableMedicinesFts}(rowid, name_ar, name_en) VALUES (new.id, new.name_ar, new.name_en);
          END
        ''');
      } catch (e) {
        if (kDebugMode) print('FTS Migration Error: $e');
      }
    }
    if (oldVersion < 14) {
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tablePrescriptions} ADD COLUMN extra_vitals TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE ${DBConstants.tableVitals} ADD COLUMN extra_vitals TEXT');
      } catch (_) {}
    }
    if (oldVersion < 16) {
      final tables = [
        DBConstants.tablePatients,
        DBConstants.tablePrescriptions,
        DBConstants.tablePrescriptionMedicines,
        DBConstants.tableVitals
      ];

      for (var table in tables) {
        await _addColumnIfMissing(db, table, 'sync_id', 'TEXT');
        await _addColumnIfMissing(
            db, table, 'updated_at', 'TEXT NOT NULL DEFAULT ""');
      }
      debugPrint(
          "✅ Database Schema Upgraded to Version 16 (Robust Sync Check).");
    }

    // 🏥 إصدار 17 و 18 - ذكاء طبي متقدم
    if (oldVersion < 17) {
      try {
        // إضافة الأعمدة الطبية الجديدة إلى جدول المرضى
        await _addColumnIfMissing(
            db, DBConstants.tablePatients, 'allergies', 'TEXT');
        await _addColumnIfMissing(
            db, DBConstants.tablePatients, 'chronic_diseases', 'TEXT');
        await _addColumnIfMissing(
            db, DBConstants.tablePatients, 'blood_group', 'TEXT');
        await _addColumnIfMissing(
            db, DBConstants.tablePatients, 'height', 'REAL');
        await _addColumnIfMissing(
            db, DBConstants.tablePatients, 'is_pregnant', 'INTEGER DEFAULT 0');
        await _addColumnIfMissing(
            db, DBConstants.tablePatients, 'age_category', 'INTEGER DEFAULT 2');

        // JSON fields للتاريخ الطبي الشامل
        await _addColumnIfMissing(db, DBConstants.tablePatients,
            'medication_history_json', 'TEXT DEFAULT "[]"');
        await _addColumnIfMissing(db, DBConstants.tablePatients,
            'current_medications_json', 'TEXT DEFAULT "[]"');
        await _addColumnIfMissing(db, DBConstants.tablePatients,
            'preexisting_conditions_json', 'TEXT DEFAULT "[]"');

        debugPrint(
            "✅ Database Upgraded to Version 17 (Patient Medical Fields)");
      } catch (e) {
        debugPrint("⚠️ Error in Version 17 upgrade: $e");
      }
    }

    if (oldVersion < 18) {
      try {
        // إضافة الأعمدة الطبية الجديدة إلى جدول الأدوية في الوصفات
        await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
            'route_of_administration', 'TEXT');
        await _addColumnIfMissing(
            db, DBConstants.tablePrescriptionMedicines, 'indication', 'TEXT');
        await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
            'warnings_and_contraindications', 'TEXT');
        await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
            'drug_interaction_risk', 'TEXT');

        // إنشاء الجداول الجديدة
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DBConstants.tableDrugInteractions} (
              id TEXT PRIMARY KEY,
              clinic_id TEXT NOT NULL,
              drug1 TEXT NOT NULL,
              drug2 TEXT NOT NULL,
              severity INTEGER DEFAULT 0,
              interaction_description TEXT NOT NULL,
              recommendation TEXT,
              evidence_source TEXT,
              is_active INTEGER DEFAULT 1,
              created_at TEXT NOT NULL,
              last_updated_at TEXT NOT NULL
            )
          ''');
          await db.execute(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_drug_interactions_unique ON ${DBConstants.tableDrugInteractions}(drug1, drug2, clinic_id)');
        } catch (e) {
          debugPrint("Note: DrugInteractions table might already exist: $e");
        }

        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DBConstants.tablePatientRiskProfiles} (
              id TEXT PRIMARY KEY,
              patient_id INTEGER NOT NULL UNIQUE,
              has_diabetes INTEGER DEFAULT 0,
              has_hypertension INTEGER DEFAULT 0,
              has_heart_disease INTEGER DEFAULT 0,
              has_kidney_disease INTEGER DEFAULT 0,
              has_liver_disease INTEGER DEFAULT 0,
              has_asthma INTEGER DEFAULT 0,
              has_thyroid_disease INTEGER DEFAULT 0,
              has_autoimmune INTEGER DEFAULT 0,
              on_immunosuppressants INTEGER DEFAULT 0,
              on_anticoagulants INTEGER DEFAULT 0,
              is_pregnant INTEGER DEFAULT 0,
              is_breastfeeding INTEGER DEFAULT 0,
              is_post_surgery INTEGER DEFAULT 0,
              risk_score INTEGER DEFAULT 0,
              special_notes TEXT,
              created_at TEXT NOT NULL,
              last_updated_at TEXT NOT NULL,
              FOREIGN KEY(patient_id) REFERENCES ${DBConstants.tablePatients}(id) ON DELETE CASCADE
            )
          ''');
          await db.execute(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_patient_risk_profiles_patient ON ${DBConstants.tablePatientRiskProfiles}(patient_id)');
        } catch (e) {
          debugPrint("Note: PatientRiskProfiles table might already exist: $e");
        }

        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DBConstants.tableMedicationTemplates} (
              id TEXT PRIMARY KEY,
              clinic_id TEXT NOT NULL,
              name TEXT NOT NULL,
              description TEXT,
              specialty TEXT,
              medicines_json TEXT DEFAULT '[]',
              is_active INTEGER DEFAULT 1,
              usage_count INTEGER DEFAULT 0,
              version INTEGER DEFAULT 1,
              created_at TEXT NOT NULL,
              last_used_at TEXT,
              last_updated_at TEXT NOT NULL
            )
          ''');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_medication_templates_clinic ON ${DBConstants.tableMedicationTemplates}(clinic_id)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_medication_templates_active ON ${DBConstants.tableMedicationTemplates}(is_active)');
        } catch (e) {
          debugPrint("Note: MedicationTemplates table might already exist: $e");
        }

        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DBConstants.tableClinicalAlerts} (
              id TEXT PRIMARY KEY,
              clinic_id TEXT NOT NULL,
              patient_id TEXT,
              prescription_id TEXT,
              alert_type INTEGER DEFAULT 0,
              priority INTEGER DEFAULT 1,
              title TEXT NOT NULL,
              message TEXT NOT NULL,
              recommendation TEXT,
              is_resolved INTEGER DEFAULT 0,
              resolved_at TEXT,
              resolution_notes TEXT,
              created_at TEXT NOT NULL,
              last_updated_at TEXT NOT NULL
            )
          ''');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_clinical_alerts_clinic ON ${DBConstants.tableClinicalAlerts}(clinic_id)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_clinical_alerts_patient ON ${DBConstants.tableClinicalAlerts}(patient_id)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_clinical_alerts_priority ON ${DBConstants.tableClinicalAlerts}(priority)');
        } catch (e) {
          debugPrint("Note: ClinicalAlerts table might already exist: $e");
        }

        debugPrint(
            "✅ Database Upgraded to Version 18 (Advanced Medical Intelligence)");
      } catch (e) {
        debugPrint("⚠️ Error in Version 18 upgrade: $e");
      }
    }

    if (oldVersion < 19) {
      try {
        await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines, 'dosage_unit', 'TEXT');
        await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines, 'frequency_detailed', 'TEXT');
        await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines, 'duration_unit', 'TEXT');
        
        debugPrint("✅ Database Upgraded to Version 19 (High-Precision Medicine Fields)");
      } catch (e) {
        debugPrint("⚠️ Error in Version 19 upgrade: $e");
      }
    }
    if (oldVersion < 21) {
      try {
        await _addColumnIfMissing(db, DBConstants.tablePrescriptions, 'height', 'REAL');
        await _addColumnIfMissing(db, DBConstants.tablePrescriptions, 'head_circ', 'REAL');
        await _addColumnIfMissing(db, DBConstants.tableVitals, 'height', 'REAL');
        await _addColumnIfMissing(db, DBConstants.tableVitals, 'head_circ', 'REAL');
        debugPrint("✅ Database Upgraded to Version 21 (Pediatric Indicators)");
      } catch (e) {
        debugPrint("⚠️ Error in Version 21 upgrade: $e");
      }
    }
  }

  /// وظيفة "الإصلاح الذاتي" للهيكل - تعمل تلقائياً كلما فُتحت قاعدة البيانات
  /// تضمن وجود الأعمدة المطلوبة للمزامنة في كل الجداول حتى لو فشل Migration
  Future<void> ensureSchemaConsistency(Database db) async {
    final tables = [
      DBConstants.tableDoctor,
      DBConstants.tablePatients,
      DBConstants.tablePrescriptions,
      DBConstants.tablePrescriptionMedicines,
      DBConstants.tableVitals
    ];
    for (var table in tables) {
      await _addColumnIfMissing(db, table, 'sync_id', 'TEXT');
      await _addColumnIfMissing(
          db, table, 'updated_at', 'TEXT NOT NULL DEFAULT ""');
      await _addColumnIfMissing(db, table, 'is_synced', 'INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, table, 'is_deleted', 'INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, table, 'follow_up_date', 'TEXT');
    }

    // Doctor Profile Specific Missing Columns (Self-Healing)
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'logo_path', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'signature_path', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'photo_path', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'bio', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'bio_en', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'name_en', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'specialty_en', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'credentials_en', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'sub_specialty', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'sub_specialty_en', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tableDoctor, 'license_number', 'TEXT');

    // Patient Specific Clinical Fields
    await _addColumnIfMissing(
        db, DBConstants.tablePatients, 'blood_group', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tablePatients, 'height', 'REAL');
    await _addColumnIfMissing(
        db, DBConstants.tablePatients, 'allergies', 'TEXT');
    await _addColumnIfMissing(
        db, DBConstants.tablePatients, 'chronic_diseases', 'TEXT');

    // 🏥 الحقول الطبية الجديدة
    await _addColumnIfMissing(
        db, DBConstants.tablePatients, 'is_pregnant', 'INTEGER DEFAULT 0');
    await _addColumnIfMissing(
        db, DBConstants.tablePatients, 'age_category', 'INTEGER DEFAULT 2');
    await _addColumnIfMissing(db, DBConstants.tablePatients,
        'medication_history_json', 'TEXT DEFAULT "[]"');
    await _addColumnIfMissing(db, DBConstants.tablePatients,
        'current_medications_json', 'TEXT DEFAULT "[]"');
    await _addColumnIfMissing(db, DBConstants.tablePatients,
        'preexisting_conditions_json', 'TEXT DEFAULT "[]"');

    // PrescriptionMedicine - الحقول الطبية
    await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
        'route_of_administration', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
        'dosage_unit', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
        'frequency_detailed', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
        'duration_unit', 'TEXT');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptionMedicines, 'indication', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
        'warnings_and_contraindications', 'TEXT');
    await _addColumnIfMissing(db, DBConstants.tablePrescriptionMedicines,
        'drug_interaction_risk', 'TEXT');

    // Ensure Vitals columns exist in Prescriptions for integrated sync
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'weight', 'REAL');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'systolic', 'INTEGER');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'diastolic', 'INTEGER');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'pulse', 'INTEGER');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'sugar', 'REAL');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'temperature', 'REAL');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'extra_vitals', 'TEXT');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'height', 'REAL');
    await _addColumnIfMissing(
        db, DBConstants.tablePrescriptions, 'head_circ', 'REAL');
    await _addColumnIfMissing(
        db, DBConstants.tableVitals, 'height', 'REAL');
    await _addColumnIfMissing(
        db, DBConstants.tableVitals, 'head_circ', 'REAL');

    debugPrint("✅ Schema Consistency Verified.");
  }

  /// وظيفة مساعدة لإضافة عمود فقط إذا كان غير موجود لمنع أخطاء Duplicate Column
  Future<void> _addColumnIfMissing(
      Database db, String table, String column, String definition) async {
    try {
      // فحص الأعمدة الموجودة حالياً في الجدول
      final List<Map<String, dynamic>> columns =
          await db.rawQuery('PRAGMA table_info($table)');

      // فحص ذكي يتجاهل حالة الأحرف (sync_id vs SYNC_ID)
      bool exists = columns.any((c) {
        final name = c['name']?.toString().toLowerCase();
        return name == column.toLowerCase();
      });

      if (!exists) {
        debugPrint("🧪 Adding column '$column' to table '$table'...");
        await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
        debugPrint("➕ Column '$column' added successfully to '$table'.");
      } else {
        debugPrint("ℹ️ Column '$column' already exists in '$table', skipping.");
      }
    } catch (e) {
      // إذا حدث خطأ بسبب أن العمود موجود بالفعل (رغم الفحص)، نقوم بتجاهله بسلام
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('duplicate column name') ||
          errorStr.contains('already exists')) {
        debugPrint(
            "ℹ️ Column '$column' exists (caught by exception), skipping.");
      } else {
        debugPrint("⚠️ Error adding column '$column' to '$table': $e");
      }
    }
  }

  // إغلاق قاعدة البيانات الحالية لتهيئة أخرى (عند تسجيل الخروج)
  Future<void> resetDb({bool shouldDelete = false}) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint("🧹 Local Database Closed.");
    }

    if (shouldDelete && _currentDbName != null) {
      try {
        if (!kIsWeb) {
          final dbPath = await getApplicationDocumentsDirectory();
          final path = join(dbPath.path, _currentDbName!);
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            debugPrint("🔥 Database file deleted: $path");
          }
        } else {
          await databaseFactory.deleteDatabase(_currentDbName!);
        }
      } catch (e) {
        debugPrint("❌ Error deleting database file: $e");
      }
    }
    _currentDbName = null;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
