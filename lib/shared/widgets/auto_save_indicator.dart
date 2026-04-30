import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auto_save_provider.dart';

class AutoSaveIndicator extends ConsumerWidget {
  const AutoSaveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(autoSaveProvider);
    
    if (status == AutoSaveStatus.idle) return const SizedBox.shrink();
    
    final isSaving = status == AutoSaveStatus.saving;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSaving ? Colors.orange.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSaving ? Icons.sync : Icons.check_circle,
            color: isSaving ? Colors.orange : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isSaving ? 'جاري الحفظ...' : 'تم الحفظ ✔',
            style: TextStyle(
              color: isSaving ? Colors.orange.shade800 : Colors.green.shade800,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
