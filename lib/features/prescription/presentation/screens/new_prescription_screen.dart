import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rachita/features/doctor/presentation/providers/doctor_provider.dart';
import 'package:rachita/features/patient/domain/entities/patient_entity.dart';
import 'package:rachita/features/patient/presentation/providers/patient_provider.dart';
import 'package:rachita/features/prescription/domain/entities/prescription_entity.dart';
import 'package:rachita/features/prescription/domain/entities/prescription_medicine_entity.dart';
import 'package:rachita/features/prescription/utils/pdf_prescription_service.dart';
import 'package:rachita/features/prescription/presentation/providers/prescription_provider.dart';
import 'package:rachita/shared/theme/app_colors.dart';
import 'package:rachita/shared/widgets/auto_save_indicator.dart';
import 'package:rachita/shared/providers/auto_save_provider.dart';
import 'package:rachita/features/medicine/presentation/widgets/medicine_search_widget.dart';
import 'package:rachita/features/medicine/domain/entities/medicine_entity.dart';
import 'package:rachita/shared/widgets/voice_button.dart';
import 'package:rachita/features/prescription/presentation/widgets/treatment_suggestions_sheet.dart';
import 'package:rachita/core/utils/clinical_logic.dart';
import 'package:rachita/core/services/clinical_safety_service.dart';
import 'package:rachita/features/prescription/presentation/widgets/clinical_alert_dialog.dart';
import 'package:rachita/features/prescription/presentation/widgets/specialty/pediatric_specialty_module.dart';
import 'package:rachita/features/prescription/presentation/widgets/specialty/general_specialty_module.dart';
import 'package:rachita/features/prescription/presentation/widgets/specialty/generic_specialty_module.dart';
import 'package:rachita/features/prescription/presentation/widgets/smart_command_center.dart';
import 'package:rachita/features/prescription/presentation/widgets/clinical_insight_panel.dart';
import 'package:rachita/features/prescription/presentation/widgets/live_interaction_panel.dart';
import 'package:rachita/features/prescription/presentation/providers/drug_interaction_provider.dart';
import 'package:rachita/features/prescription/presentation/providers/medical_intelligence_providers.dart';
import 'package:rachita/core/services/smart_voice_command_service.dart';
import 'package:rachita/core/services/clinical_dosage_calculator.dart';
import 'package:rachita/core/services/audit_service.dart';
import 'package:rachita/core/services/medication_reminder_service.dart';
import 'dart:ui';



class NewPrescriptionScreen extends ConsumerStatefulWidget {
  final int patientId;
  const NewPrescriptionScreen({super.key, required this.patientId});

  @override
  ConsumerState<NewPrescriptionScreen> createState() => _NewPrescriptionScreenState();
}

class _NewPrescriptionScreenState extends ConsumerState<NewPrescriptionScreen> {
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  final _headCircCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();

  int _selectedPatientId = 0;
  List<PrescriptionMedicineEntity> _medicines = [];
  List<String> _attachments = [];
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final current = ref.read(currentPrescriptionProvider);
      if (current != null && current.patientId == _selectedPatientId) {
        _diagnosisController.text = current.diagnosis;
        _notesController.text = current.notes ?? '';
        _attachments = List.from(current.attachments ?? []);
        _weightCtrl.text = current.weight?.toString() ?? '';
        _systolicCtrl.text = current.systolic?.toString() ?? '';
        _diastolicCtrl.text = current.diastolic?.toString() ?? '';
        _pulseCtrl.text = current.pulse?.toString() ?? '';
        _sugarCtrl.text = current.sugar?.toString() ?? '';
        _tempCtrl.text = current.temperature?.toString() ?? '';
        _heightCtrl.text = current.height?.toString() ?? '';
        _headCircCtrl.text = current.headCirc?.toString() ?? '';
        if (current.medicines != null) _medicines = List.from(current.medicines!);
      }
      _isInit = true;
    }
  }

  void _triggerAutoSave() {
    ref.read(autoSaveProvider.notifier).onFieldChanged(() async {
      if (!mounted) return;
      final current = ref.read(currentPrescriptionProvider);
      final entity = PrescriptionEntity(
        id: current?.id,
        patientId: _selectedPatientId,
        diagnosis: _diagnosisController.text.isEmpty ? 'التشخيص الأساسي' : _diagnosisController.text,
        notes: _notesController.text,
        date: current?.date ?? DateTime.now(),
        attachments: _attachments,
        createdAt: current?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        medicines: List.from(_medicines), // Clone to prevent ConcurrentModificationError
        weight: double.tryParse(_weightCtrl.text),
        systolic: int.tryParse(_systolicCtrl.text),
        diastolic: int.tryParse(_diastolicCtrl.text),
        pulse: int.tryParse(_pulseCtrl.text),
        sugar: double.tryParse(_sugarCtrl.text),
        temperature: double.tryParse(_tempCtrl.text),
        height: double.tryParse(_heightCtrl.text),
        headCirc: double.tryParse(_headCircCtrl.text),
      );
      if (_selectedPatientId != 0) {
        if (!mounted) return;
        await ref.read(prescriptionActionProvider).savePrescription(entity);
      } else {
        if (!mounted) return;
        ref.read(currentPrescriptionProvider.notifier).state = entity;
      }
    });
  }

  void _addMedicine(MedicineEntity medicine) {
    HapticFeedback.lightImpact();
    double weight = double.tryParse(_weightCtrl.text) ?? 0.0;
    String dosage = medicine.commonDose ?? '1';
    String freq = medicine.commonFreq ?? 'مرة يومياً';

    if (weight > 0) {
      final calc = ClinicalDosageCalculator.calculatePediatricDose(medicine.nameEn ?? medicine.nameAr, weight);
      if (calc != null) {
        dosage = '${calc.calculatedDoseMl} مل (${calc.calculatedDoseMg.toInt()}mg)';
        freq = calc.frequency;
      }
    }

    final med = PrescriptionMedicineEntity(
      medicineName: medicine.nameAr,
      medicineNameEn: medicine.nameEn,
      dosage: dosage,
      frequency: freq,
      duration: '5 أيام',
      routeOfAdmin: 'Oral',
      updatedAt: DateTime.now(),
    );
    setState(() => _medicines.add(med));
    _triggerAutoSave();
  }

  void _removeMedicine(int index) {
    setState(() => _medicines.removeAt(index));
    _triggerAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientByIdProvider(_selectedPatientId));
    final rxsAsync = ref.watch(patientPrescriptionsProvider(_selectedPatientId));
    PrescriptionEntity? lastRx;
    if (rxsAsync.hasValue && rxsAsync.value!.isNotEmpty) {
      final list = rxsAsync.value!;
      lastRx = list.firstWhere((element) => element.id != ref.read(currentPrescriptionProvider)?.id, orElse: () => list.first);
    }

    final doctor = ref.watch(doctorProvider).value;
    final requiredVitals = ClinicalLogic.getRequiredVitals(doctor?.specialty ?? 'General');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildSmartIntegrationBar(),
          ),
          _buildProfessionalHeader(context, patientAsync),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSafetyBanner(context, ref),
                const SizedBox(height: 16),
                SmartCommandCenter(
                  onCommandExecuted: (result) {
                    _handleSmartCommand(result);
                  },
                ),
                const SizedBox(height: 16),
                // 🏥 لوحة التفاعلات الدوائية الحية
                const LiveInteractionPanel(),
                const SizedBox(height: 8),
                // 🧠 لوحة الاستنتاج السريري
                if (patientAsync.hasValue && patientAsync.value != null)
                  ClinicalInsightPanel(
                    patient: patientAsync.value!,
                    diagnosis: _diagnosisController.text,
                    medicines: _medicines.map((m) => m.medicineName).toList(),
                    vitals: {
                      'systolic': double.tryParse(_systolicCtrl.text) ?? 0,
                      'diastolic': double.tryParse(_diastolicCtrl.text) ?? 0,
                      'sugar': double.tryParse(_sugarCtrl.text) ?? 0,
                      'weight': double.tryParse(_weightCtrl.text) ?? 0,
                    },
                  ),
                const SizedBox(height: 24),
                _buildSectionHeader('المؤشرات الحيوية السريرية', Icons.monitor_heart_outlined),
                const SizedBox(height: 16),
                _buildSpecialtyModule(doctor?.specialty ?? 'General', lastRx),
                const SizedBox(height: 32),
                _buildSectionHeader('التشخيص والخطة العلاجية', Icons.psychology_outlined),
                const SizedBox(height: 16),
                _buildInputPanel(
                  _diagnosisController, 
                  'اكتب التشخيص الطبي أو تحدث مباشرة...', 
                  Icons.psychology_alt_rounded, 
                  maxLines: 3,
                  suffix: IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                    onPressed: _showSmartSuggestions,
                    tooltip: 'اقتراحات ذكية',
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputPanel(_notesController, 'تعليمات إضافية للمريض...', Icons.info_outline_rounded, maxLines: 2, isMuted: true),
                const SizedBox(height: 32),
                _buildSectionHeader('الأدوية والوصفات', Icons.medication_outlined),
                const SizedBox(height: 16),
                MedicineSearchWidget(
                  onMedicineSelected: (m) => _addMedicine(m),
                  onStructuredMedicineSelected: (presMed) {
                    final exists = _medicines.any((m) => m.medicineName == presMed.medicineName && m.dosage == presMed.dosage);
                    if (!exists) {
                      setState(() => _medicines.add(presMed));
                      _triggerAutoSave();
                    }
                  },
                ),
                const SizedBox(height: 16),
                ..._medicines.asMap().entries.map((e) => _buildMedicineTile(e.value, e.key)),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            )
          ]
        ),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.mic_none_rounded, size: 26),
          label: const Text('المساعد الصوتي الذكي', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
          onPressed: _openVoiceCopilot,
        ),
      ),
    );
  }

  void _openVoiceCopilot() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1A2236).withValues(alpha: 0.85) 
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 50)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.psychology_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('أتحدث، أنا أستمع...', style: TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text('يمكنك إملاء التشخيص وعدة أدوية في جملة واحدة\nمثال: "المريض يعاني من التهاب، اصرف اوجمنتين وبروفين"', 
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              VoiceButton(
                contextId: 'prescription_entry',
                size: 64,
                onResult: (text) async {
                  Navigator.pop(c);
                  final service = ref.read(smartVoiceCommandServiceProvider);
                  final results = await service.processBatchCommands(text);
                  for (final res in results) {
                    _handleSmartCommand(res);
                  }
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader(BuildContext context, AsyncValue<PatientEntity?> pAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1A2236) : Colors.white;
    final headerBorder = isDark ? const Color(0xFF2A3A52) : AppColors.divider;
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: headerBg,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20,
            color: isDark ? Colors.white70 : AppColors.textPrimary),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(bottom: BorderSide(color: headerBorder)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 40),
            child: pAsync.when(
              data: (p) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إنشاء روشتة طبية ذكية', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(p?.name ?? 'المريض...', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: isDark ? Colors.white : AppColors.textPrimary, letterSpacing: -0.5)),
                  if (p != null && ((p.allergies?.isNotEmpty ?? false) || (p.chronicDiseases?.isNotEmpty ?? false))) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (p.allergies?.isNotEmpty ?? false) 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 14),
                                const SizedBox(width: 4),
                                Text('حساسية: ${p.allergies}', style: const TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        if ((p.allergies?.isNotEmpty ?? false) && (p.chronicDiseases?.isNotEmpty ?? false)) const SizedBox(width: 8),
                        if (p.chronicDiseases?.isNotEmpty ?? false)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.medical_services_outlined, color: Colors.orange, size: 14),
                                const SizedBox(width: 4),
                                Text('مزمن: ${p.chronicDiseases}', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ),
      ),
      actions: const [Padding(padding: EdgeInsets.only(right: 24), child: AutoSaveIndicator())],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
      ],
    );
  }



  Widget _buildInputPanel(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1, bool isMuted = false, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: AppColors.textPrimary, fontWeight: isMuted ? FontWeight.w500 : FontWeight.w700, fontSize: isMuted ? 14 : 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.5), size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (suffix != null) suffix,
              VoiceButton(
                contextId: hint,
                size: 32,
                onResult: (text) {
                  ctrl.text = isMuted ? text : (ctrl.text + ' ' + text).trim();
                  _triggerAutoSave();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (_) => _triggerAutoSave(),
      ),
    );
  }

  Widget _buildMedicineTile(PrescriptionMedicineEntity med, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primaryLight, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10)]
                ), 
                child: const Icon(Icons.medication_liquid_rounded, color: AppColors.primary, size: 24)
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(med.medicineName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
              ),
              IconButton(onPressed: () => _removeMedicine(index), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22)),
            ],
          ),
          const SizedBox(height: 20),
          // Medicine Details Form
          Row(
            children: [
              Expanded(flex: 2, child: _medInputField('الجرعة', med.dosage, (val) {
                _medicines[index] = med.copyWith(dosage: val);
                _triggerAutoSave();
              })),
              const SizedBox(width: 12),
              Expanded(child: _medInputField('الوحدة', med.dosageUnit ?? 'ملغ', (val) {
                _medicines[index] = med.copyWith(dosageUnit: val);
                _triggerAutoSave();
              })),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _medInputField('التكرار', med.frequency, (val) {
                _medicines[index] = med.copyWith(frequency: val);
                _triggerAutoSave();
              })),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 2, child: _medInputField('المدة', med.duration, (val) {
                _medicines[index] = med.copyWith(duration: val);
                _triggerAutoSave();
              })),
              const SizedBox(width: 12),
              Expanded(child: _medInputField('وحدة المدة', med.durationUnit ?? 'يوم', (val) {
                _medicines[index] = med.copyWith(durationUnit: val);
                _triggerAutoSave();
              })),
            ],
          ),
          if (med.instructions != null && med.instructions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _medInputField('تعليمات إضافية (اختياري)...', med.instructions ?? '', (val) {
              _medicines[index] = med.copyWith(instructions: val);
              _triggerAutoSave();
            }, isFullWidth: true),
          ]
        ],
      ),
    );
  }

  Widget _medInputField(String label, String initialValue, Function(String) onChanged, {bool isFullWidth = false}) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }

  void _handleSaveAndPrint() async {
    final safety = ref.read(safetyReportProvider);
    if (safety.errors.isNotEmpty) {
      final proceed = await ClinicalAlertDialog.show(
        context,
        title: 'تنبيه سريري حرج ⚠️',
        message: safety.errors.join('\n'),
        isCritical: true,
      );
      if (!proceed) return;
    } else if (safety.warnings.isNotEmpty) {
       await ClinicalAlertDialog.show(
        context,
        title: 'ملاحظات سلامة 💡',
        message: safety.warnings.join('\n'),
        isCritical: false,
      );
    }

    HapticFeedback.mediumImpact();
    final current = ref.read(currentPrescriptionProvider);
    final doctor = ref.read(doctorProvider).value;
    final patient = ref.read(patientByIdProvider(_selectedPatientId)).value;

    if (doctor == null || patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إكمال ملف الطبيب والبيانات أولاً')));
      return;
    }

    final entity = PrescriptionEntity(
      id: current?.id,
      patientId: _selectedPatientId,
      diagnosis: _diagnosisController.text.isEmpty ? 'التشخيص الأساسي' : _diagnosisController.text,
      notes: _notesController.text,
      date: current?.date ?? DateTime.now(),
      attachments: _attachments,
      createdAt: current?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      medicines: List.from(_medicines), // Clone to prevent ConcurrentModificationError
      weight: double.tryParse(_weightCtrl.text),
      systolic: int.tryParse(_systolicCtrl.text),
      diastolic: int.tryParse(_diastolicCtrl.text),
      pulse: int.tryParse(_pulseCtrl.text),
      sugar: double.tryParse(_sugarCtrl.text),
      temperature: double.tryParse(_tempCtrl.text),
    );

    final actionNotifier = ref.read(prescriptionActionProvider);
    await actionNotifier.savePrescription(entity);

    // 🔐 Audit Log
    ref.read(auditServiceProvider).logAction(
      action: 'PRESCRIPTION_SAVED',
      userId: doctor.id.toString(),
      entityType: 'prescription',
      entityId: entity.id?.toString(),
      details: 'التشخيص: ${entity.diagnosis}, عدد الأدوية: ${_medicines.length}',
    );

    // 🔔 Medication Reminders
    final reminderService = ref.read(medicationReminderServiceProvider);
    for (final med in _medicines) {
      // Schedule at 8:00 AM by default if no specific time logic exists yet
      // In a real app, you might parse "frequency" to set multiple times
      await reminderService.scheduleReminder(
        patientId: _selectedPatientId,
        patientName: patient.name,
        medicineName: med.medicineName,
        time: '08:00', // Default dose time
        prescriptionId: entity.id,
      );
    }

    if (mounted) {
      await PdfPrescriptionService.generateAndPrint(
        doctor: doctor,
        patient: patient,
        prescription: entity,
        languageCode: 'ar',
      );
    }
  }

  void _showSmartSuggestions() {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TreatmentSuggestionsSheet(
        diagnosis: _diagnosisController.text,
        systolic: double.tryParse(_systolicCtrl.text),
        diastolic: double.tryParse(_diastolicCtrl.text),
        weight: double.tryParse(_weightCtrl.text),
        sugar: double.tryParse(_sugarCtrl.text),
        onApply: (medicines) {
          setState(() {
            _medicines.addAll(medicines);
          });
          _triggerAutoSave();
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: AppColors.divider)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleSaveAndPrint,
              icon: const Icon(Icons.print_rounded, size: 20),
              label: const Text('حفظ وطباعة الروشتة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner(BuildContext context, WidgetRef ref) {
    final safety = ref.watch(safetyReportProvider);
    if (!safety.hasIssues && safety.riskScore < 3) return const SizedBox();

    final isError = safety.errors.isNotEmpty;
    final color = isError ? AppColors.error : (safety.riskScore >= 3 ? Colors.orange : AppColors.primary);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.report_problem_rounded : Icons.info_outline_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isError ? 'تم اكتشاف مخاطر سريرية!' : 'تنبيهات سلامة طبية',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  isError ? safety.errors.first : (safety.warnings.isNotEmpty ? safety.warnings.first : 'يرجى مراجعة الجرعات والمؤشرات.'),
                  style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          if (isError) 
            TextButton(
              onPressed: () => _handleSaveAndPrint(), 
              child: const Text('تفاصيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
            ),
        ],
      ),
    );
  }
  Widget _buildSpecialtyModule(String specialtyName, PrescriptionEntity? lastRx) {
    final controllers = {
      'weight': _weightCtrl,
      'systolic': _systolicCtrl,
      'diastolic': _diastolicCtrl,
      'pulse': _pulseCtrl,
      'temp': _tempCtrl,
      'sugar': _sugarCtrl,
      'head_circ': _headCircCtrl,
      'height': _heightCtrl,
    };

    if (specialtyName.contains('أطفال') || specialtyName.toLowerCase().contains('pediatric')) {
      return PediatricSpecialtyModule(
        lastPrescription: lastRx,
        controllers: controllers,
        onChanged: _triggerAutoSave,
      );
    }
    
    // Generic/Precise Dispatcher
    return GenericSpecialtyModule(
      specialtyLabel: specialtyName,
      lastPrescription: lastRx,
      controllers: controllers,
      onChanged: _triggerAutoSave,
    );
  }

  void _handleSmartCommand(SmartCommandResult result) {
    HapticFeedback.mediumImpact();
    switch (result.intent) {
      case CommandIntent.diagnose:
        if (result.data?['diagnosis'] != null) {
          setState(() => _diagnosisController.text = result.data!['diagnosis']);
          _triggerAutoSave();
        }
        break;
      case CommandIntent.prescribe:
        if (result.data != null) {
          String medName = result.data!['medicine_name'] ?? 'دواء غير معروف';
          String dosage = result.data!['dosage'] ?? '1';
          String freq = result.data!['frequency'] ?? 'مرة يومياً';
          
          double weight = double.tryParse(_weightCtrl.text) ?? 0.0;
          if (weight > 0 && dosage == '1') {
            final calc = ClinicalDosageCalculator.calculatePediatricDose(medName, weight);
            if (calc != null) {
              dosage = '${calc.calculatedDoseMl} مل (${calc.calculatedDoseMg.toInt()}mg)';
              freq = calc.frequency;
            }
          }

          final med = PrescriptionMedicineEntity(
            medicineName: medName,
            dosage: dosage,
            frequency: freq,
            duration: result.data!['duration'] ?? '5 أيام',
            routeOfAdmin: 'Oral',
            updatedAt: DateTime.now(),
          );
          setState(() => _medicines.add(med));
          _triggerAutoSave();
        }
        break;
      case CommandIntent.save:
        _handleSaveAndPrint();
        break;
      case CommandIntent.print:
        _handleSaveAndPrint();
        break;
      case CommandIntent.dictation:
        if (result.data?['text'] != null) {
          setState(() => _diagnosisController.text += ' ' + result.data!['text']);
          _triggerAutoSave();
        }
        break;
      case CommandIntent.clear:
        setState(() {
          _diagnosisController.clear();
          _medicines.clear();
        });
        _triggerAutoSave();
        break;
    }
  }

  Widget _buildSmartIntegrationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'المساعد الذكي نشط: تحليل التفاعلات، فحص الحمل، وتنبؤ الجرعات مفعل.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () => _showIntelligenceGuide(),
            icon: const Icon(Icons.help_outline, size: 14),
            label: const Text('كيف أستخدمه؟', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showIntelligenceGuide() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('دليل المساعد السريري الذكي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildGuideItem(Icons.mic, 'الأوامر الصوتية', 'قل "صرف بنادول" أو "تشخيص التهاب" لإدخال البيانات فوراً.'),
            _buildGuideItem(Icons.security, 'الأمان الحي', 'يقوم النظام بفحص تفاعلات الأدوية مع سجل المريض لحظياً.'),
            _buildGuideItem(Icons.psychology, 'الاستنتاج المنطقي', 'يحلل النظام ضغط الدم والسكر ليقترح تعديل الجرعات أو يحذر من أدوية معينة.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('فهمت، لنبدأ!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


