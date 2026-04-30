import 'package:flutter/material.dart';
import 'package:rachita/shared/theme/app_colors.dart';
import 'package:rachita/core/utils/clinical_logic.dart';
import 'specialty_module_base.dart';
import 'clinical_vital_input.dart';

class GenericSpecialtyModule extends SpecialtyModule {
  final String specialtyLabel;

  const GenericSpecialtyModule({
    super.key,
    required this.specialtyLabel,
    required super.lastPrescription,
    required super.controllers,
    required super.onChanged,
  });

  @override
  String get specialtyName => specialtyLabel;

  @override
  IconData get icon => Icons.medical_services_rounded;

  @override
  Widget build(BuildContext context) {
    final requiredKeys = ClinicalLogic.getRequiredVitals(specialtyLabel);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'مؤشرات اختصاص $specialtyLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 24,
            alignment: WrapAlignment.start,
            children: requiredKeys.map((key) {
              return _buildIndicator(key);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String key) {
    String label = '';
    IconData icon = Icons.analytics_outlined;
    Color color = AppColors.primary;
    double? lastVal;

    switch (key) {
      case 'weight':
        label = 'الوزن (كغ)';
        icon = Icons.scale_outlined;
        color = AppColors.secondary;
        lastVal = lastPrescription?.weight;
        break;
      case 'systolic':
        label = 'الضغط (S)';
        icon = Icons.speed_rounded;
        color = AppColors.error;
        lastVal = lastPrescription?.systolic?.toDouble();
        break;
      case 'diastolic':
        label = 'الضغط (D)';
        icon = Icons.low_priority_rounded;
        color = Colors.red.shade700;
        lastVal = lastPrescription?.diastolic?.toDouble();
        break;
      case 'temperature':
      case 'temp':
        label = 'الحرارة (C)';
        icon = Icons.thermostat_outlined;
        color = AppColors.warning;
        lastVal = lastPrescription?.temperature;
        break;
      case 'pulse':
        label = 'النبض (BPM)';
        icon = Icons.monitor_heart_outlined;
        color = AppColors.primary;
        lastVal = lastPrescription?.pulse?.toDouble();
        break;
      case 'sugar':
        label = 'السكر (mg/dL)';
        icon = Icons.water_drop_outlined;
        color = Colors.orange;
        lastVal = lastPrescription?.sugar;
        break;
      case 'height':
        label = 'الطول (سم)';
        icon = Icons.height_rounded;
        color = Colors.blue;
        lastVal = lastPrescription?.height;
        break;
      case 'head_circ':
        label = 'محيط الرأس';
        icon = Icons.face_rounded;
        color = Colors.teal;
        lastVal = lastPrescription?.headCirc;
        break;
      default:
        label = key;
    }

    return ClinicalVitalInput(
      label: label,
      controller: controllers[key] ?? TextEditingController(),
      icon: icon,
      color: color,
      lastValue: lastVal,
      onChanged: onChanged,
    );
  }
}
