import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/localization/app_localizations.dart';
import '../providers/medical_intelligence_providers.dart';

import '../../domain/hybrid_suggestion_engine.dart';
import '../../data/doctor_patterns_repository.dart';
import '../../data/treatment_protocols.dart';
import '../../domain/entities/prescription_medicine_entity.dart';
import '../../../doctor/presentation/providers/doctor_provider.dart';

class TreatmentSuggestionsSheet extends ConsumerStatefulWidget {
  final String diagnosis;
  final double? systolic;
  final double? diastolic;
  final double? sugar;
  final double? weight;
  final int? patientAge;
  final Function(List<PrescriptionMedicineEntity>) onApply;

  const TreatmentSuggestionsSheet({
    super.key,
    required this.diagnosis,
    this.systolic,
    this.diastolic,
    this.sugar,
    this.weight,
    this.patientAge,
    required this.onApply,
  });

  @override
  ConsumerState<TreatmentSuggestionsSheet> createState() => _TreatmentSuggestionsSheetState();
}

class _TreatmentSuggestionsSheetState extends ConsumerState<TreatmentSuggestionsSheet> {
  HybridSuggestionResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final engine = ref.read(hybridSuggestionEngineProvider);
    final doctor = ref.read(doctorProvider).value;
    
    final result = await engine.getSuggestions(
      diagnosis: widget.diagnosis,
      speciality: doctor?.specialty ?? 'General',
      systolic: widget.systolic,
      diastolic: widget.diastolic,
      sugar: widget.sugar,
      weight: widget.weight,
      patientAge: widget.patientAge,
    );

    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (_result?.vitalsWarnings.isNotEmpty ?? false)
                      _buildWarningsBanner(),
                    
                    if (_result?.clinicalSafetyNotes.isNotEmpty ?? false)
                      _buildSafetyNotesSection(),

                    if (_result?.weightAdjustedNote != null)
                      _buildWeightNote(),

                    const SizedBox(height: 16),
                    
                    if (_result?.learnedSuggestions.isNotEmpty ?? false) ...[
                      _buildSectionTitle(context.tr('from_your_experience'), count: _result!.learnedSuggestions.length, icon: Icons.history_edu_outlined),
                      const SizedBox(height: 12),
                      ..._result!.learnedSuggestions.map((p) => _buildLearnedCard(p as DoctorPattern)),

                      const SizedBox(height: 32),
                    ],

                    if (_result?.staticProtocols.isNotEmpty ?? false) ...[
                      _buildSectionTitle(context.tr('specialty_protocols'), icon: Icons.verified_outlined),
                      const SizedBox(height: 12),
                      ..._result!.staticProtocols.map((p) => _buildProtocolCard(p as TreatmentProtocol)),

                    ],

                    if ((_result?.learnedSuggestions.isEmpty ?? true) && 
                        (_result?.staticProtocols.isEmpty ?? true))
                      _buildEmptyState(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final doctor = ref.watch(doctorProvider).value;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('smart_treatment_suggestion'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              if (doctor?.specialty != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(doctor!.specialty, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        children: _result!.vitalsWarnings.map((w) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.gpp_maybe_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(w, style: const TextStyle(fontSize: 14, color: AppColors.error, fontWeight: FontWeight.bold))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSafetyNotesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(context.tr('clinical_safety_advisor'), 
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ..._result!.clinicalSafetyNotes.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(n, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWeightNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.secondaryDark, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_result!.weightAdjustedNote!, style: const TextStyle(fontSize: 14, color: AppColors.secondaryDark, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {int? count, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(count.toString(), style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildLearnedCard(DoctorPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(pattern.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text('${pattern.dosage ?? ""} - ${pattern.frequency ?? ""}', style: const TextStyle(color: AppColors.textSecondary)),
        trailing: ElevatedButton(
          onPressed: () => _applyMedicines([
            PrescriptionMedicineEntity(
              medicineName: pattern.medicineName,
              medicineNameEn: pattern.medicineNameEn,
              dosage: pattern.dosage ?? '',
              frequency: pattern.frequency ?? '',
              duration: pattern.duration ?? '',
              routeOfAdmin: pattern.routeOfAdmin,
              updatedAt: DateTime.now(),
            )
          ]),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(context.tr('add'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildProtocolCard(TreatmentProtocol protocol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(protocol.diagnosisAr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text(protocol.diagnosisEn, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final meds = protocol.medicines.map((m) => PrescriptionMedicineEntity(
                      medicineName: m.nameAr,
                      medicineNameEn: m.nameEn,
                      dosage: m.dosage,
                      frequency: m.frequency,
                      duration: m.duration,
                      routeOfAdmin: m.routeOfAdmin,
                      instructions: m.note,
                      updatedAt: DateTime.now(),
                    )).toList();
                    _applyMedicines(meds);
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: Text(context.tr('apply_protocol'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const Divider(color: AppColors.divider, height: 24),
            ...protocol.medicines.map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.medication_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${m.nameAr} (${m.dosage} - ${m.frequency})',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(context.tr('no_smart_suggestions_yet'), style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  void _applyMedicines(List<PrescriptionMedicineEntity> medicines) {
    widget.onApply(medicines);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medicines.length} ${context.tr('medicines_added_successfully')}'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
