import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rachita/shared/localization/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/responsive_wrapper.dart';
import '../../../doctor/presentation/providers/doctor_provider.dart';
import '../../../patient/presentation/providers/patient_provider.dart';
import '../../../prescription/presentation/providers/prescription_provider.dart';
import '../../../patient/presentation/screens/patient_list_screen.dart';
import '../../../../shared/providers/navigation_provider.dart';

class ClinicDashboardScreen extends ConsumerWidget {
  const ClinicDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorProvider);
    final patientCountAsync = ref.watch(globalPatientCountProvider);
    final rxCountAsync = ref.watch(globalPrescriptionCountProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, doctorAsync),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsGrid(patientCountAsync, rxCountAsync),
                const SizedBox(height: 32),
                _buildActionCard(
                  context,
                  title: context.tr('new_prescription_dash'),
                  subtitle: context.tr('new_prescription_sub'),
                  icon: Icons.add_task_rounded,
                  color: AppColors.primary,
                  onTap: () {
                     // Navigate to patient list or show search modal
                     ref.read(navigationIndexProvider.notifier).state = 1; // Switch to Patient List tab
                  },
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context,
                  title: context.tr('clinic_analysis_dash'),
                  subtitle: context.tr('clinic_analysis_sub'),
                  icon: Icons.analytics_outlined,
                  color: AppColors.secondary,
                  onTap: () {
                    ref.read(navigationIndexProvider.notifier).state = 2; // Switch to Settings
                  },
                ),
                const SizedBox(height: 32),
                Text(context.tr('medical_tip_title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 32),
                _buildTipCard(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AsyncValue doctorAsync) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
          child: doctorAsync.when(
            data: (doctor) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('مرحباً، د. ${doctor?.name ?? "..."}', 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Theme.of(context).textTheme.displayLarge?.color, letterSpacing: -1.0)),
                const SizedBox(height: 4),
                Text(doctor?.specialty ?? "تخصص طبي غير محدد", 
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AsyncValue<int> pCount, AsyncValue<int> rxCount) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isWide ? 4 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          _statCard(context, context.tr('patients'), pCount.when(data: (c) => '$c', loading: () => '...', error: (_, __) => '0'), Icons.people_alt_rounded, AppColors.primary),
          _statCard(context, context.tr('prescriptions'), rxCount.when(data: (c) => '$c', loading: () => '...', error: (_, __) => '0'), Icons.medication_rounded, AppColors.secondary),
          _statCard(context, context.tr('settings'), 'V1.2', Icons.settings_suggest_rounded, AppColors.accent),
          _statCard(context, context.tr('urgent_cases'), '0', Icons.emergency_rounded, AppColors.error),
        ],
      );
    });
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Theme.of(context).textTheme.displayLarge?.color)),
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).textTheme.titleLarge?.color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              context.tr('medical_tip_content'),
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.amberAccent : const Color(0xFF7F5F00), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
