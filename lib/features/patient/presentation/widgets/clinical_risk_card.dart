import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/patient_entity.dart';

class ClinicalRiskCard extends StatelessWidget {
  final PatientEntity patient;

  const ClinicalRiskCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final riskData = _calculateRisk();
    final Color riskColor = riskData['color'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            riskColor.withOpacity(0.15),
            riskColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: riskColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(riskData['icon'], color: riskColor, size: 24),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'تقييم المخاطر السريرية',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: riskColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  riskData['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            riskData['description'],
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (riskData['factors'].isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (riskData['factors'] as List<String>).map((factor) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: riskColor.withOpacity(0.1)),
                  ),
                  child: Text(
                    factor,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: riskColor.withOpacity(0.8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateRisk() {
    int score = 0;
    List<String> factors = [];

    // Age factor
    if (patient.age != null) {
      if (patient.age! > 65) {
        score += 2;
        factors.add('العمر > 65');
      } else if (patient.age! < 12) {
        score += 1;
        factors.add('مرحلة الطفولة');
      }
    }

    // Chronic diseases
    if (patient.chronicDiseases != null && patient.chronicDiseases!.isNotEmpty) {
      score += 3;
      factors.add('أمراض مزمنة');
    }

    // Pregnancy
    if (patient.isPregnant) {
      score += 2;
      factors.add('حالة حمل');
    }

    // Allergies
    if (patient.allergies != null && patient.allergies!.isNotEmpty) {
      score += 1;
      factors.add('حساسية مسجلة');
    }

    if (score >= 5) {
      return {
        'status': 'عالي الخطورة',
        'color': AppColors.error,
        'icon': Icons.gpp_maybe_rounded,
        'description': 'المريض يتطلب مراقبة مكثفة وتدقيق في التداخلات الدوائية.',
        'factors': factors,
      };
    } else if (score >= 2) {
      return {
        'status': 'متوسط الخطورة',
        'color': AppColors.warning,
        'icon': Icons.shield_outlined,
        'description': 'يوجد عوامل خطر معتدلة، يرجى مراجعة التاريخ المرضي قبل الوصف.',
        'factors': factors,
      };
    } else {
      return {
        'status': 'مستقر',
        'color': AppColors.success,
        'icon': Icons.verified_user_outlined,
        'description': 'المؤشرات السريرية الحالية مستقرة ولا توجد عوامل خطر رئيسية.',
        'factors': factors,
      };
    }
  }
}
