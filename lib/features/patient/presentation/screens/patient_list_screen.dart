import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rachita/shared/localization/app_localizations.dart';
import '../../domain/entities/patient_entity.dart';
import '../providers/patient_provider.dart';
import 'patient_detail_screen.dart';
import '../../../../shared/theme/app_colors.dart';

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSearchHeader(context),
          Expanded(
            child: patientsAsync.when(
              data: (patients) {
                final filtered = patients.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || (p.phone?.contains(_searchQuery) ?? false)).toList();
                if (filtered.isEmpty) return _buildEmptyState();
                return _buildPatientList(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.textSecondary))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPatientDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(context.tr('add_new_patient'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: context.tr('search_patient_hint'),
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(List<PatientEntity> patients) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      itemCount: patients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildPatientCard(patients[index]),
    );
  }

  Widget _buildPatientCard(PatientEntity patient) {
    final themeColor = patient.gender == 'male' ? AppColors.primary : Colors.pinkAccent;
    return Dismissible(
      key: Key('patient_${patient.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (dir) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr('confirm_delete')),
            content: Text(context.tr('confirm_delete_content').replaceAll('{name}', patient.name)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete'), style: const TextStyle(color: AppColors.error))),
            ],
          ),
        );
      },
      onDismissed: (dir) => ref.read(patientsProvider.notifier).deletePatient(patient.id!),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: patient))),
          onLongPress: () => _showPatientDialog(patientToEdit: patient),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    patient.gender == 'male' ? Icons.face_rounded : Icons.face_3_rounded, 
                    color: themeColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: 4),
                      Text(patient.phone ?? context.tr('no_phone'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                    ],
                  ),
                ),
                _buildCardActions(patient),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardActions(PatientEntity patient) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'edit') {
          _showPatientDialog(patientToEdit: patient);
        } else if (val == 'delete') {
          ref.read(patientsProvider.notifier).deletePatient(patient.id!).then((error) {
            if (error != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: AppColors.error),
              );
            }
          });
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18), const SizedBox(width: 8), Text(context.tr('edit_patient'))])),
        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), const SizedBox(width: 8), Text(context.tr('delete'), style: const TextStyle(color: AppColors.error))])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 70, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(context.tr('no_search_results'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  void _showPatientDialog({PatientEntity? patientToEdit}) {
    final nameCtrl = TextEditingController(text: patientToEdit?.name);
    final phoneCtrl = TextEditingController(text: patientToEdit?.phone);
    final ageCtrl = TextEditingController(text: patientToEdit?.age?.toString());
    final heightCtrl = TextEditingController(text: patientToEdit?.height?.toString());
    final allergiesCtrl = TextEditingController(text: patientToEdit?.allergies);
    final chronicCtrl = TextEditingController(text: patientToEdit?.chronicDiseases);
    String gender = patientToEdit?.gender ?? 'male';
    String? bloodGroup = patientToEdit?.bloodGroup;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(patientToEdit == null ? 'إضافة مريض' : 'تعديل بيانات مريض', 
            style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.titleLarge?.color)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'اسم المريض', Icons.person_outline),
                const SizedBox(height: 16),
                _dialogField(phoneCtrl, 'رقم الهاتف', Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _dialogField(ageCtrl, 'العمر', Icons.calendar_today_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _dialogField(heightCtrl, 'الطول (سم)', Icons.height, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildBloodGroupDropdown(bloodGroup, (v) => setS(() => bloodGroup = v)),
                const SizedBox(height: 16),
                _dialogField(chronicCtrl, 'الأمراض المزمنة', Icons.medical_services_outlined, maxLines: 2),
                const SizedBox(height: 16),
                _dialogField(allergiesCtrl, 'الحساسية والموانع', Icons.warning_amber_rounded, maxLines: 2),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _genderOption('male', context.tr('male'), gender, (v) => setS(() => gender = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _genderOption('female', context.tr('female'), gender, (v) => setS(() => gender = v))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                final p = PatientEntity(
                  id: patientToEdit?.id, 
                  name: nameCtrl.text, 
                  phone: phoneCtrl.text, 
                  age: int.tryParse(ageCtrl.text), 
                  gender: gender,
                  height: double.tryParse(heightCtrl.text),
                  bloodGroup: bloodGroup,
                  chronicDiseases: chronicCtrl.text,
                  allergies: allergiesCtrl.text,
                  createdAt: patientToEdit?.createdAt ?? DateTime.now(), 
                  updatedAt: DateTime.now()
                );
                
                String? error;
                if (patientToEdit == null) {
                  error = await ref.read(patientsProvider.notifier).addPatient(p);
                } else {
                  error = await ref.read(patientsProvider.notifier).updatePatient(p);
                }

                if (mounted) {
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(context.tr('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildBloodGroupDropdown(String? current, Function(String?) onChanged) {
    const groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    return DropdownButtonFormField<String>(
      value: current,
      decoration: InputDecoration(
        labelText: 'فصيلة الدم',
        prefixIcon: const Icon(Icons.bloodtype_outlined, color: AppColors.error),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _genderOption(String type, String label, String current, Function(String) onSelect) {
    final active = current == type;
    return InkWell(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : Theme.of(context).dividerColor),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
