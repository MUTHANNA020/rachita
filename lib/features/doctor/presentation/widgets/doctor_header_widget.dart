import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/localization/app_localizations.dart';

class DoctorHeaderWidget extends StatelessWidget {
  final DoctorEntity doctor;
  final bool showBranding;

  const DoctorHeaderWidget({
    super.key,
    required this.doctor,
    this.showBranding = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final name = locale == 'en' ? (doctor.nameEn ?? doctor.name) : doctor.name;
    final specialty = locale == 'en' ? (doctor.specialtyEn ?? doctor.specialty) : doctor.specialty;
    final credentials = locale == 'en' ? (doctor.credentialsEn ?? doctor.credentials) : doctor.credentials;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBranding && doctor.logoPath != null && doctor.logoPath!.isNotEmpty && (doctor.logoPath!.startsWith('data:image') || doctor.logoPath!.startsWith('http') || (!kIsWeb && File(doctor.logoPath!).existsSync())))
            Container(
              margin: const EdgeInsetsDirectional.only(end: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: doctor.logoPath!.startsWith('data:image') 
                    ? Image.memory(base64Decode(doctor.logoPath!.split(',').last), width: 70, height: 70, fit: BoxFit.cover)
                    : (kIsWeb || doctor.logoPath!.startsWith('http')
                        ? Image.network(doctor.logoPath!, width: 70, height: 70, fit: BoxFit.cover)
                        : Image.file(
                            File(doctor.logoPath!),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.apartment_rounded, size: 40, color: AppColors.primary),
                        )),
              ),
            )
          else
            Container(
              width: 70,
              height: 70,
              margin: const EdgeInsetsDirectional.only(end: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 36),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('doctor_title')}$name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                Text(
                  specialty,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (credentials != null && credentials.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      credentials,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business_center_outlined, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Expanded(child: Text(doctor.clinicName, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
