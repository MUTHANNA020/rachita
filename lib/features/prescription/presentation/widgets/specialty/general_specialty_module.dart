import 'package:flutter/material.dart';
import 'package:rachita/shared/theme/app_colors.dart';
import 'specialty_module_base.dart';
import 'clinical_vital_input.dart';

class GeneralSpecialtyModule extends SpecialtyModule {
  const GeneralSpecialtyModule({
    super.key,
    required super.lastPrescription,
    required super.controllers,
    required super.onChanged,
  });

  @override
  String get specialtyName => 'ممارسة عامة';

  @override
  IconData get icon => Icons.medical_services_outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppColors.border)
      ),
      child: Wrap(
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
            label: 'الضغط (SYS)', 
            controller: controllers['systolic']!, 
            icon: Icons.favorite_border_rounded, 
            color: AppColors.error,
            lastValue: lastPrescription?.systolic?.toDouble(),
            onChanged: onChanged,
          ),
          ClinicalVitalInput(
            label: 'الضغط (DIA)', 
            controller: controllers['diastolic']!, 
            icon: Icons.favorite_outline_rounded, 
            color: AppColors.error,
            lastValue: lastPrescription?.diastolic?.toDouble(),
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
            label: 'السكر', 
            controller: controllers['sugar']!, 
            icon: Icons.water_drop_outlined, 
            color: AppColors.accent,
            lastValue: lastPrescription?.sugar,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
