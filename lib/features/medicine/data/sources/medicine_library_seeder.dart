import '../../domain/entities/medicine_entity.dart';

class MedicineLibrarySeeder {
  static List<MedicineEntity> getMedicines() {
    return [
      // ── Antibiotics ──────────────────────────────────────────────────────────
      MedicineEntity(nameAr: 'أموكسيسيلين', nameEn: 'Amoxicillin', category: 'Antibiotic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'أوجمنتين', nameEn: 'Augmentin', category: 'Antibiotic', commonDose: '1g', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'أزيثروميسين', nameEn: 'Azithromycin', category: 'Antibiotic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيبروفلوكساسين', nameEn: 'Ciprofloxacin', category: 'Antibiotic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'كلاريثروميسين', nameEn: 'Clarithromycin', category: 'Antibiotic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'فلاجيل', nameEn: 'Flagyl (Metronidazole)', category: 'Antibiotic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'دوكسيسيكلين', nameEn: 'Doxycycline', category: 'Antibiotic', commonDose: '100mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ليفوفلوكساسين', nameEn: 'Levofloxacin', category: 'Antibiotic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيفوروكزيم', nameEn: 'Cefuroxime', category: 'Antibiotic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيفالكسين', nameEn: 'Cephalexin', category: 'Antibiotic', commonDose: '500mg', updatedAt: DateTime.now()),

      // ── Pain & Anti-inflammatory ──────────────────────────────────────────────
      MedicineEntity(nameAr: 'باراسيتامول', nameEn: 'Paracetamol (Panadol)', category: 'Analgesic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'إيبوبروفين', nameEn: 'Ibuprofen (Brufen/Advil)', category: 'NSAID', commonDose: '400mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ديكلوفيناك صوديوم', nameEn: 'Diclofenac (Voltaren)', category: 'NSAID', commonDose: '50mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'نابروكسين', nameEn: 'Naproxen', category: 'NSAID', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيليكوكسيب', nameEn: 'Celecoxib (Celebrex)', category: 'NSAID', commonDose: '200mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ترامادول', nameEn: 'Tramadol', category: 'Opioid Analgesic', commonDose: '50mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ميلوكسيكام', nameEn: 'Meloxicam', category: 'NSAID', commonDose: '15mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'أسبرين', nameEn: 'Aspirin', category: 'Antiplatelet', commonDose: '75mg', updatedAt: DateTime.now()),

      // ── Hypertension & Cardiac ────────────────────────────────────────────────
      MedicineEntity(nameAr: 'أملوديبين', nameEn: 'Amlodipine (Norvasc)', category: 'Calcium Channel Blocker', commonDose: '5mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ليسينوبريل', nameEn: 'Lisinopril', category: 'ACE Inhibitor', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'لوزارتان', nameEn: 'Losartan (Cozaar)', category: 'ARB', commonDose: '50mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'فالسارتان', nameEn: 'Valsartan (Diovan)', category: 'ARB', commonDose: '80mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'أتينولول', nameEn: 'Atenolol', category: 'Beta Blocker', commonDose: '50mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'بيسوبرولول', nameEn: 'Bisoprolol (Concor)', category: 'Beta Blocker', commonDose: '5mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ميتوبرولول', nameEn: 'Metoprolol', category: 'Beta Blocker', commonDose: '50mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'فاروارين', nameEn: 'Warfarin', category: 'Anticoagulant', commonDose: '5mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'أتورفاستاتين', nameEn: 'Atorvastatin (Lipitor)', category: 'Statin', commonDose: '20mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'روسوفاستاتين', nameEn: 'Rosuvastatin (Crestor)', category: 'Statin', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيمفاستاتين', nameEn: 'Simvastatin', category: 'Statin', commonDose: '20mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'فوروسيميد', nameEn: 'Furosemide (Lasix)', category: 'Diuretic', commonDose: '40mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'هيدروكلوروثيازيد', nameEn: 'Hydrochlorothiazide', category: 'Diuretic', commonDose: '25mg', updatedAt: DateTime.now()),

      // ── Diabetes ──────────────────────────────────────────────────────────────
      MedicineEntity(nameAr: 'ميتفورمين', nameEn: 'Metformin (Glucophage)', category: 'Antidiabetic', commonDose: '500mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'جليكلازيد', nameEn: 'Gliclazide (Diamicron)', category: 'Sulfonylurea', commonDose: '30mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيتاجليبتين', nameEn: 'Sitagliptin (Januvia)', category: 'DPP-4 Inhibitor', commonDose: '100mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'إمباغليفلوزين', nameEn: 'Empagliflozin (Jardiance)', category: 'SGLT2 Inhibitor', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'أنسولين لانتوس', nameEn: 'Insulin Glargine (Lantus)', category: 'Insulin', commonDose: '10 Units', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'نوفورابيد', nameEn: 'Insulin Aspart (NovoRapid)', category: 'Insulin', commonDose: 'Slide Scale', updatedAt: DateTime.now()),

      // ── Gastrointestinal ──────────────────────────────────────────────────────
      MedicineEntity(nameAr: 'أوميبرازول', nameEn: 'Omeprazole (Losec)', category: 'PPI', commonDose: '20mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'إيسوميبرازول', nameEn: 'Esomeprazole (Nexium)', category: 'PPI', commonDose: '40mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'بانتوبرازول', nameEn: 'Pantoprazole (Protonix)', category: 'PPI', commonDose: '40mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'فاموتيدين', nameEn: 'Famotidine', category: 'H2 Blocker', commonDose: '20mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ميتوكلوبراميد', nameEn: 'Metoclopramide', category: 'Antiemetic', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'دومبيريدون', nameEn: 'Domperidone (Motilium)', category: 'Antiemetic', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'بسكوبان', nameEn: 'Buscopan (Hyoscine)', category: 'Antispasmodic', commonDose: '10mg', updatedAt: DateTime.now()),

      // ── Respiratory & Allergy ─────────────────────────────────────────────────
      MedicineEntity(nameAr: 'فنتولين', nameEn: 'Salbutamol (Ventolin)', category: 'Bronchodilator', commonDose: '100mcg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيمبيكورت', nameEn: 'Symbicort', category: 'Inhaler', commonDose: '160/4.5', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيريتيد', nameEn: 'Seretide', category: 'Inhaler', commonDose: '250', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'مونتيلوكاست', nameEn: 'Montelukast (Singulair)', category: 'Leukotriene receptor antagonist', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'سيتريزين', nameEn: 'Cetirizine (Zyrtec)', category: 'Antihistamine', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'لوراتادين', nameEn: 'Loratadine (Claritin)', category: 'Antihistamine', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'فيكسوفينادين', nameEn: 'Fexofenadine (Allegra)', category: 'Antihistamine', commonDose: '120mg', updatedAt: DateTime.now()),

      // ── Central Nervous System ────────────────────────────────────────────────
      MedicineEntity(nameAr: 'سيرترالين', nameEn: 'Sertraline (Zoloft)', category: 'SSRI', commonDose: '50mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'إسيتالوبرام', nameEn: 'Escitalopram', category: 'SSRI', commonDose: '10mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'فلوكسيتين', nameEn: 'Fluoxetine (Prozac)', category: 'SSRI', commonDose: '20mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ألفبرازولام', nameEn: 'Alprazolam (Xanax)', category: 'Anxiolytic', commonDose: '0.25mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'ديازيبام', nameEn: 'Diazepam (Valium)', category: 'Benzodiazepine', commonDose: '5mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'جابابنتين', nameEn: 'Gabapentin (Neurontin)', category: 'Anticonvulsant', commonDose: '300mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'بريجابالين', nameEn: 'Pregabalin (Lyrica)', category: 'Anticonvulsant', commonDose: '75mg', updatedAt: DateTime.now()),

      // ── Miscellaneous ─────────────────────────────────────────────────────────
      MedicineEntity(nameAr: 'ليفوثيروكسين', nameEn: 'Levothyroxine', category: 'Thyroid Hormone', commonDose: '100mcg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'فيتامين د', nameEn: 'Vitamin D3', category: 'Supplement', commonDose: '1000 IU', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'حمض الفوليك', nameEn: 'Folic Acid', category: 'Supplement', commonDose: '5mg', updatedAt: DateTime.now()),
      MedicineEntity(nameAr: 'حديد', nameEn: 'Ferrous Sulfate', category: 'Supplement', commonDose: '200mg', updatedAt: DateTime.now()),
    ];
  }
}
