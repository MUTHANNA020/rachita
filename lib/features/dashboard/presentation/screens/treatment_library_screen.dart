import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../doctor/presentation/providers/doctor_provider.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';

final treatmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  // Get all medicines with their clinical data
  final List<Map<String, dynamic>> maps = await db.query(
    DBConstants.tableMedicines,
    orderBy: 'use_count DESC',
  );
  return maps;
});

class TreatmentLibraryScreen extends ConsumerWidget {
  const TreatmentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorProvider);
    final treatmentsAsync = ref.watch(treatmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildProfessionalHeader(context, doctorAsync),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: _buildSectionTitle('دليل العلاجات المتوفرة', Icons.medical_information_outlined),
            ),
          ),
          treatmentsAsync.when(
            data: (treatments) {
              if (treatments.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_liquid_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('دليل العلاجات فارغ حالياً', style: TextStyle(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final treatment = treatments[index];
                      return _buildTreatmentCard(treatment);
                    },
                    childCount: treatments.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('خطأ في تحميل العلاجات: $e', style: const TextStyle(color: AppColors.error))),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader(BuildContext context, AsyncValue<dynamic> doctorAsync) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('المكتبة السريرية والأدوية', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                doctorAsync.when(
                  data: (doc) => Text('د. ${doc?.name ?? "الزميل العزيز"}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => const Text('دكتور راشيتا', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
      ],
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> treatment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.vaccines_outlined, color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(treatment['name_ar'] ?? 'غير محدد', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
                      if (treatment['name_en'] != null && treatment['name_en'].toString().isNotEmpty)
                        Text(treatment['name_en'], style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTreatmentDetail('الجرعة', treatment['common_dose'] ?? 'حسب التشخيص', Icons.scale_outlined, AppColors.primary),
                  ),
                  Container(width: 1, height: 40, color: AppColors.divider),
                  Expanded(
                    child: _buildTreatmentDetail('التكرار والأوقات', treatment['common_freq'] ?? 'حسب الحاجة', Icons.access_time_outlined, AppColors.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentDetail(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14), textAlign: TextAlign.center),
      ],
    );
  }
}
