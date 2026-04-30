# 🏥 نظام الذكاء الطبي الشامل - دليل الاستخدام

## نظرة عامة

تم بناء نظام ذكاء طبي متقدم يوفر:
- 🚨 تنبيهات سريرية ذكية
- 💊 فحص تفاعلات الأدوية الشاملة
- 📊 تقييم مخاطر المريض المتقدم
- 🧠 توصيات هجينة ذكية
- 💡 حسابات جرعات مخصصة

---

## التطبيق في الواجهة الأمامية (Flutter)

### 1. استيراد الموارد المطلوبة

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/prescription/presentation/widgets/clinical_alerts_widget.dart';
import 'features/prescription/presentation/providers/medical_intelligence_providers.dart';
import 'features/prescription/domain/hybrid_suggestion_engine.dart';
```

### 2. عرض التنبيهات السريرية

```dart
// في شاشة الوصفة الجديدة
final suggestionParams = HybridSuggestionParams(
  diagnosis: 'ألم الرأس',
  speciality: 'طب عام',
  patientAge: patient.age,
  ageCategory: patient.ageCategory, // 0-4: Pediatric/Adolescent/Adult/Geriatric/Elderly
  isPregnant: patient.isPregnant,
  allergies: patient.allergies,
  chronicDiseases: patient.chronicDiseases,
  currentMedicines: ['Aspirin', 'Metformin'],
  systolic: 140,
  diastolic: 90,
  sugar: 180,
  weight: 70,
);

// عرض الواجهة
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: ClinicalAlertsWidget(
      patientId: patient.id.toString(),
      prescriptionId: prescription.id.toString(),
      suggestionParams: suggestionParams,
    ),
  ),
);
```

### 3. الوصول إلى الخدمات مباشرة

```dart
class MyPrescriptionPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الحصول على الخدمات
    final alertService = ref.watch(clinicalAlertServiceProvider);
    final interactionService = ref.watch(drugInteractionServiceProvider);
    final riskService = ref.watch(riskAssessmentServiceProvider);
    
    return Scaffold(
      // الاستخدام
    );
  }
}
```

---

## التطبيق في Backend (C#)

### 1. إضافة Endpoints للتنبيهات السريرية

```csharp
[HttpPost("prescription/{id}/check-alerts")]
public async Task<IActionResult> CheckClinicalAlerts(Guid id)
{
    var prescription = await _context.Prescriptions
        .Include(p => p.Patient)
        .FirstOrDefaultAsync(p => p.Id == id);
    
    if (prescription == null)
        return NotFound();
    
    var alerts = GenerateClinicalAlerts(prescription);
    
    // حفظ التنبيهات في قاعدة البيانات
    await _context.ClinicalAlerts.AddRangeAsync(alerts);
    await _context.SaveChangesAsync();
    
    return Ok(alerts);
}

private List<ClinicalAlert> GenerateClinicalAlerts(Prescription prescription)
{
    var alerts = new List<ClinicalAlert>();
    
    // فحص تفاعلات الأدوية
    var drugNames = prescription.PrescriptionMedicines
        .Select(pm => pm.MedicineName)
        .ToList();
    
    // تطبيق منطق الذكاء الطبي هنا
    
    return alerts;
}
```

### 2. استعلام التنبيهات الحرجة

```csharp
[HttpGet("clinic/{clinicId}/critical-alerts")]
public async Task<IActionResult> GetCriticalAlerts(Guid clinicId)
{
    var criticalAlerts = await _context.ClinicalAlerts
        .Where(a => a.ClinicId == clinicId && 
                    a.Priority == AlertPriority.Critical &&
                    !a.IsResolved)
        .OrderByDescending(a => a.CreatedAt)
        .ToListAsync();
    
    return Ok(criticalAlerts);
}
```

### 3. تحديث حالة التنبيه

```csharp
[HttpPut("alerts/{id}/resolve")]
public async Task<IActionResult> ResolveAlert(Guid id, ResolveAlertRequest request)
{
    var alert = await _context.ClinicalAlerts.FindAsync(id);
    if (alert == null)
        return NotFound();
    
    alert.IsResolved = true;
    alert.ResolvedAt = DateTime.UtcNow;
    alert.ResolutionNotes = request.Notes;
    
    await _context.SaveChangesAsync();
    return Ok(alert);
}

public class ResolveAlertRequest
{
    public string Notes { get; set; }
}
```

---

## نموذج استخدام عملي

### سيناريو: مريض جديد مع وصفة

```dart
// 1. جمع بيانات المريض
final patient = PatientModel(
  name: 'محمد علي',
  age: 7, // طفل
  ageCategory: 0, // Pediatric
  height: 1.2,
  allergies: 'Penicillin',
  chronicDiseases: 'Asthma',
  isPregnant: false,
  currentMedicationsJson: jsonEncode(['Albuterol']),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 2. إنشاء وصفة جديدة
final prescription = PrescriptionModel(
  patientId: patient.id!,
  diagnosis: 'عدوى الجهاز التنفسي',
  doctorNotes: 'درجة الحرارة 38.5',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 3. فحص التفاعلات
final interactionService = DrugInteractionService();
final medicines = ['Amoxicillin', 'Albuterol'];
final interactions = interactionService.checkMultipleInteractions(medicines);
// النتيجة: تحذير - Amoxicillin يسبب حساسية + Penicillin allergy

// 4. الحصول على توصيات ذكية
final engine = HybridSuggestionEngine(repo);
final suggestions = await engine.getSuggestions(
  diagnosis: 'عدوى',
  speciality: 'طب الأطفال',
  patientAge: 7,
  ageCategory: 0,
  allergies: 'Penicillin',
  currentMedicines: ['Albuterol'],
);
// سيعطي تنبيهات: مضاد حيوي آمن للأطفال، احذر من الحساسية

// 5. تقييم المخاطر
final riskService = RiskAssessmentService();
final risk = riskService.assessPatientRisk(
  age: 7,
  ageCategory: 0,
  allergies: 'Penicillin',
  chronicDiseases: 'Asthma',
  // ...
);
// درجة المخاطرة: 35 (معتدل) - تفاعلات محتملة + طفل صغير
```

---

## أنواع التنبيهات

| النوع | الوصف | الأيقونة |
|------|-------|--------|
| `allergicReaction` | حساسية من أدوية | ⚠️ |
| `drugInteraction` | تفاعل بين أدويتين أو أكثر | 💊 |
| `pregnancyWarning` | تحذير أثناء الحمل | 🤰 |
| `ageInappropriate` | دواء غير مناسب للعمر | 👶 |
| `contraindicatedCondition` | دواء موانع للحالة | 🚫 |
| `dosaageWarning` | تحذير الجرعة | 📊 |
| `longTermRisk` | خطر طويل الأجل | ⏰ |
| `kidneyFunction` / `liverFunction` | مشاكل كلوية/كبدية | 🩺 |

---

## مستويات الأولوية

| المستوى | اللون | الرمز | التأثير |
|--------|------|------|--------|
| `critical` | 🔴 أحمر | 🚨 | يجب الوقف فوراً |
| `warning` | 🟠 برتقالي | ⚠️ | تصرف بحذر |
| `info` | 🔵 أزرق | ℹ️ | معلومة فقط |

---

## نصائح الاستخدام

### 1. فحص سريع قبل الوصفة
```dart
// في new_prescription_screen.dart
final criticalAlerts = suggestions.allCriticalAlerts;
if (criticalAlerts.isNotEmpty) {
  showWarningDialog(context, criticalAlerts);
}
```

### 2. تتبع المخاطر العالية
```dart
// يومي للمرضى الحرجين (risk >= 60)
if (riskAssessment.requiresImmediateAttention) {
  notifyDoctor(riskAssessment);
}
```

### 3. الامتثال للتوصيات
```dart
// عرض التوصيات إلى الطبيب
for (final recommendation in riskAssessment.recommendations) {
  displayRecommendation(context, recommendation);
}
```

---

## الأداء والتخزين المؤقت

- ✅ تخزين مؤقت في الذاكرة للنتائج المتكررة
- ✅ حد أقصى 50 نتيجة مخزنة مؤقتاً
- ✅ تحديث سريع عند إعادة الحساب

---

## الأمان والخصوصية

- ✅ جميع البيانات محفوظة في قاعدة البيانات
- ✅ تنبيهات التحقق من الوصول للمريض
- ✅ سجل كامل للتنبيهات والقرارات
- ✅ يمكن تتبع من حل التنبيه ومتى

---

## المراحل القادمة

### المرحلة 7: لوحة الطبيب
- عرض الحالات الحرجة
- الوصفات المعلقة
- المتابعات المستحقة
- القوالب المحفوظة

### المرحلة 8: التحسينات
- تعلم آلي للأنماط الطبية
- تقارير تفصيلية
- إحصائيات المريض
- نموذج تنبؤي للمضاعفات

---

## الدعم والمراجع

لأي استفسارات أو تحديثات، يرجى الرجوع إلى:
- `/backend/` - شفرة C#
- `/lib/features/prescription/` - شفرة Flutter
- `/assets/data/` - بيانات المرجع
