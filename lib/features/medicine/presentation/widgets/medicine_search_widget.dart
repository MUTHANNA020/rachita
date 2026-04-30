import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/medicine_entity.dart';
import '../providers/medicine_provider.dart';
import '../../../../shared/localization/app_localizations.dart';
import '../../../../shared/widgets/voice_button.dart';
import '../../../../core/utils/medical_speech_normalizer.dart';
import '../../../../shared/theme/app_colors.dart';

import '../../../prescription/domain/entities/prescription_medicine_entity.dart';

class MedicineSearchWidget extends ConsumerStatefulWidget {
  final Function(MedicineEntity) onMedicineSelected;
  final Function(PrescriptionMedicineEntity)? onStructuredMedicineSelected;

  const MedicineSearchWidget({
    super.key, 
    required this.onMedicineSelected,
    this.onStructuredMedicineSelected,
  });

  @override
  ConsumerState<MedicineSearchWidget> createState() => _MedicineSearchWidgetState();
}

class _MedicineSearchWidgetState extends ConsumerState<MedicineSearchWidget> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _fromVoice = false; // Track if latest query came from voice

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value, {bool fromVoice = false}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _query = value.trim();
          _fromVoice = fromVoice;
        });
      }
    });
  }

  /// Called when voice result arrives — parse then search.
  void _onVoiceResult(String raw) {
    final parsed = MedicalSpeechNormalizer.parseMedicineCommand(raw);
    _searchController.text = parsed.name;
    
    // If we have structured data, notify parent immediately if it's a known medicine
    if (parsed.dosage.isNotEmpty || parsed.frequency.isNotEmpty) {
       _searchController.text = parsed.name;
       _onSearchChanged(parsed.name, fromVoice: true);
    } else {
       _onSearchChanged(parsed.name, fromVoice: true);
    }
  }

  void _selectMedicine(MedicineEntity med) {
    if (med.id != null) {
      ref.read(medicineNotifierProvider).incrementUsage(med.id!);
    }

    // Check if we had structured voice data
    final rawVoice = _fromVoice ? _searchController.text : '';
    if (_fromVoice && widget.onStructuredMedicineSelected != null) {
       final parsed = MedicalSpeechNormalizer.parseMedicineCommand(_searchController.text);
       widget.onStructuredMedicineSelected!(
         PrescriptionMedicineEntity(
           medicineName: med.nameEn ?? med.nameAr,
           medicineNameEn: med.nameEn,
           dosage: parsed.dosage.isNotEmpty ? parsed.dosage : (med.commonDose ?? '1'),
           dosageUnit: parsed.dosageUnit,
           frequency: parsed.frequency.isNotEmpty ? parsed.frequency : (med.commonFreq ?? 'مرة يومياً'),
           duration: parsed.duration.isNotEmpty ? parsed.duration : '5 أيام',
           routeOfAdmin: parsed.route,
           updatedAt: DateTime.now(),
         )
       );
    } else {
       widget.onMedicineSelected(med);
    }
    
    _fromVoice = false; // Reset immediately to prevent duplicate triggers
    _searchController.clear();
    _onSearchChanged('');
    _focusNode.unfocus();
  }

  void _addCustomMedicine() {
    if (_query.trim().isEmpty) return;
    // Apply normalizer even to custom entries
    final corrected = MedicalSpeechNormalizer.normalize(_query.trim());
    widget.onMedicineSelected(
      MedicineEntity(nameAr: corrected, updatedAt: DateTime.now()),
    );
    _searchController.clear();
    _onSearchChanged('');
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search Field ────────────────────────────────────────────────────
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.tr('search_medicine'),
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
            prefixIcon: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 22),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.primary.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1.5),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VoiceButton(
                    contextId: 'medicine_search',
                    onResult: _onVoiceResult,
                    onPartial: (text) {
                      _searchController.text = text;
                      _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
                    },
                    languageCode: 'en_US',
                    medicalMode: true,
                    size: 36,
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── Results Dropdown ────────────────────────────────────────────────
        if (_query.length >= 2)
          Consumer(
            builder: (context, ref, _) {
              final result = ref.watch(medicineSearchProvider(_query));
              return result.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (medicines) {
                  // If voice produced an exact match, auto-select immediately
                  if (_fromVoice && medicines.length == 1) {
                    final captureRef = ref;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _fromVoice) {
                        _selectMedicine(medicines.first);
                      }
                    });
                  }

                  if (medicines.isEmpty && _query.length < 3) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: medicines.length + 1,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                        ),
                        itemBuilder: (context, index) {
                          // ── Last item: "Add as custom" ──────────────────
                          if (index == medicines.length) {
                            final alreadyExists = medicines.any(
                              (m) => m.nameAr.toLowerCase() == _query.toLowerCase() ||
                                     (m.nameEn?.toLowerCase() == _query.toLowerCase()),
                            );
                            if (!alreadyExists) {
                              return _buildCustomEntry(context);
                            }
                            return const SizedBox.shrink();
                          }

                          // ── Medicine result item ────────────────────────
                          return _buildMedicineItem(context, medicines[index]);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildMedicineItem(BuildContext context, MedicineEntity med) {
    return InkWell(
      onTap: () => _selectMedicine(med),
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // English name prominently (primary for clinicians)
                  if (med.nameEn != null && med.nameEn!.isNotEmpty)
                    Text(
                      med.nameEn!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  // Arabic name below
                  Text(
                    med.nameAr,
                    style: TextStyle(
                      fontWeight: med.nameEn == null ? FontWeight.w700 : FontWeight.w500,
                      fontSize: med.nameEn == null ? 15 : 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  if (med.category != null || med.commonDose != null)
                    Text(
                      [med.category, med.commonDose]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomEntry(BuildContext context) {
    final corrected = MedicalSpeechNormalizer.normalize(_query.trim());
    final isKnown = MedicalSpeechNormalizer.isKnownDrug(_query.trim());

    return InkWell(
      onTap: _addCustomMedicine,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isKnown
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isKnown ? Icons.check_circle_outline_rounded : Icons.add_rounded,
                color: isKnown ? AppColors.primary : Colors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    corrected,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isKnown ? AppColors.primary : Colors.orange,
                    ),
                  ),
                  Text(
                    isKnown
                        ? context.tr('custom_medicine')
                        : context.tr('custom_medicine'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
