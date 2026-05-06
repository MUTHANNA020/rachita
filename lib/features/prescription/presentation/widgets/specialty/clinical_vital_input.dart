import 'package:flutter/material.dart';
import 'package:rachita/shared/theme/app_colors.dart';
import 'package:rachita/core/utils/clinical_logic.dart';
import 'package:rachita/shared/widgets/voice_button.dart';

class ClinicalVitalInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color color;
  final double? lastValue;
  final VoidCallback onChanged;

  const ClinicalVitalInput({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.color,
    this.lastValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget? trendWidget;
    if (lastValue != null && controller.text.isNotEmpty) {
      final currentVal = double.tryParse(controller.text);
      if (currentVal != null) {
        final diff = currentVal - lastValue!;
        if (diff != 0) {
          final isUp = diff > 0;
          final diffColor = isUp ? AppColors.warning : AppColors.secondary;
          trendWidget = Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: diffColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: diffColor, size: 10),
                const SizedBox(width: 2),
                Text(diff.abs().toStringAsFixed(diff.truncateToDouble() == diff ? 0 : 1), style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        } else {
          trendWidget = const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('ثابت', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          );
        }
      }
    } else if (lastValue != null) {
      trendWidget = Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('السابق: $lastValue', style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }

    // Real-time Interpretation
    BPStatus? bpStatus;
    TempStatus? tempStatus;
    String interpretation = '';
    Color statusColor = AppColors.textSecondary;

    if (controller.text.isNotEmpty) {
      if (label.contains('الضغط')) {
        bpStatus = ClinicalLogic.interpretBP(int.tryParse(controller.text), null);
        interpretation = ClinicalLogic.getBPStatusAr(bpStatus);
        statusColor = ClinicalLogic.getBPColor(bpStatus);
      } else if (label.contains('الحرارة')) {
        tempStatus = ClinicalLogic.interpretTemp(double.tryParse(controller.text));
        if (tempStatus == TempStatus.fever) {
          interpretation = 'ارتفاع حرارة ⚠️';
          statusColor = AppColors.error;
        } else if (tempStatus == TempStatus.hypothermia) {
          interpretation = 'انخفاض حرارة ❄️';
          statusColor = Colors.blue;
        }
      }
    }

    final isCrisis = bpStatus == BPStatus.crisis || tempStatus == TempStatus.fever;

    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(
                color: isCrisis ? AppColors.error : AppColors.divider,
                width: isCrisis ? 2 : 1
              ),
              boxShadow: isCrisis
                ? [BoxShadow(color: AppColors.error.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)]
                : null,
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isCrisis ? AppColors.error : AppColors.textPrimary, 
                fontWeight: FontWeight.w900, 
                fontSize: 17
              ),
              decoration: InputDecoration(
                border: InputBorder.none, 
                contentPadding: const EdgeInsets.symmetric(vertical: 14), 
                isDense: true,
                hintText: '--',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                suffixIcon: VoiceButton(
                  contextId: label,
                  size: 24,
                  onResult: (text) {
                    // Extract number from text
                    final numberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
                    if (numberMatch != null) {
                      controller.text = numberMatch.group(1)!;
                      onChanged();
                    }
                  },
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (interpretation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                interpretation,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (trendWidget != null) trendWidget,
        ],
      ),
    );
  }
}
