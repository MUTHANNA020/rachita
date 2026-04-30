import 'package:flutter/material.dart';
import 'package:rachita/shared/theme/app_colors.dart';
import 'specialty_module_base.dart';
import 'clinical_vital_input.dart';

class PediatricSpecialtyModule extends SpecialtyModule {
  const PediatricSpecialtyModule({
    super.key,
    required super.lastPrescription,
    required super.controllers,
    required super.onChanged,
  });

  @override
  String get specialtyName => 'طب الأطفال';

  @override
  IconData get icon => Icons.child_care_rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppColors.border)
      ),
      child: Column(
        children: [
          _buildPediatricAlert(),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16, runSpacing: 20, alignment: WrapAlignment.spaceEvenly,
            children: [
              ClinicalVitalInput(
                label: 'الوزن (كغ)', 
                controller: controllers['weight']!, 
                icon: Icons.scale_outlined, 
                color: AppColors.secondary,
                lastValue: lastPrescription?.weight,
                onChanged: onChanged,
              ),
              ClinicalVitalInput(
                label: 'الحرارة (C)', 
                controller: controllers['temp']!, 
                icon: Icons.thermostat_outlined, 
                color: AppColors.warning,
                lastValue: lastPrescription?.temperature,
                onChanged: onChanged,
              ),
              ClinicalVitalInput(
                label: 'النبض (BPM)', 
                controller: controllers['pulse']!, 
                icon: Icons.monitor_heart_outlined, 
                color: AppColors.primary,
                lastValue: lastPrescription?.pulse?.toDouble(),
                onChanged: onChanged,
              ),
              ClinicalVitalInput(
                label: 'محيط الرأس', 
                controller: controllers['head_circ'] ?? TextEditingController(), 
                icon: Icons.face_rounded, 
                color: Colors.teal,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDoseHelper(),
        ],
      ),
    );
  }

  Widget _buildPediatricAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('يتم حساب الجرعات تلقائياً بناءً على الوزن المدخل.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue))),
        ],
      ),
    );
  }

  Widget _buildDoseHelper() {
    final weight = double.tryParse(controllers['weight']?.text ?? '');
    if (weight == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مساعد الجرعة السريع (mg/kg):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _doseItem('10 mg/kg', (weight * 10).toStringAsFixed(1)),
              _doseItem('15 mg/kg', (weight * 15).toStringAsFixed(1)),
              _doseItem('20 mg/kg', (weight * 20).toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doseItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('$value mg', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
      ],
    );
  }
}
