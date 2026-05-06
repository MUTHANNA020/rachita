import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class MedicationListWidget extends StatelessWidget {
  final String jsonList;
  final String title;
  final IconData icon;
  final Color themeColor;

  const MedicationListWidget({
    super.key,
    required this.jsonList,
    required this.title,
    required this.icon,
    this.themeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> medications = [];
    if (jsonList.trim().isNotEmpty) {
      try {
        medications = jsonDecode(jsonList);
      } catch (_) {
        // Silently fail or log malformed JSON
      }
    }

    if (medications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            const Text(
              'لا توجد سجلات حالية',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: themeColor, size: 18),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...medications.map((med) => _buildMedCard(med)).toList(),
      ],
    );
  }

  Widget _buildMedCard(dynamic med) {
    // Assuming med is Map<String, dynamic> or a String
    String name = '';
    String details = '';
    
    if (med is Map) {
      name = med['name'] ?? med['medicine_name'] ?? 'دواء غير محدد';
      details = '${med['dosage'] ?? ''} ${med['frequency'] ?? ''}'.trim();
    } else {
      name = med.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medication_rounded, color: themeColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: AppColors.textMuted.withOpacity(0.5)),
        ],
      ),
    );
  }
}
