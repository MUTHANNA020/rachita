import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class ClinicalAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isCritical;

  const ClinicalAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.isCritical = false,
  });

  static Future<bool> show(BuildContext context, {required String title, required String message, bool isCritical = false}) async {
    return await showDialog(
      context: context,
      barrierDismissible: !isCritical,
      builder: (context) => ClinicalAlertDialog(title: title, message: message, isCritical: isCritical),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppColors.error : Colors.orange;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Icon(isCritical ? Icons.gpp_maybe_rounded : Icons.info_outline_rounded, size: 48, color: color),
      title: Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.6, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          if (isCritical) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: color, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'الاستمرار قد يعرض المريض لمخاطر صحية. يرجى تأكيد القرار الطبي.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      actions: [
        if (isCritical)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء وتعديل الوصفة', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(isCritical ? 'استمرار على مسؤوليتي' : 'موافق', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
