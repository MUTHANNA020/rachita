import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/localization/app_localizations.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../doctor/presentation/screens/doctor_profile_screen.dart';
import '../../../account/presentation/screens/account_management_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar.large(
            title: Text(context.tr('settings'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)),
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            stretch: true,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const FlexibleSpaceBar(background: SizedBox()),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // ── PREFERENCE GROUP ───────────────────────────────────────────
                _buildSectionTitle(context, context.tr('customization')),
                _buildSettingsGroup(context, isDark, [
                  _buildThemeToggle(context, ref, isDark),
                  _buildDivider(context, isDark),
                  _buildLangToggle(context, ref, settings.locale.languageCode),
                ]),

                const SizedBox(height: 28),

                // ── CLINIC ADMIN GROUP ───────────────────────────────────────────
                _buildSectionTitle(context, context.tr('personal_info')),
                _buildSettingsGroup(context, isDark, [
                  _buildNavRow(
                    context: context,
                    title: context.tr('edit_profile'),
                    icon: Icons.person_outline_rounded,
                    color: Colors.blue,
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorProfileScreen())),
                  ),
                  _buildDivider(context, isDark),
                  _buildNavRow(
                    context: context,
                    title: context.tr('cloud_management'),
                    icon: Icons.shield_outlined,
                    color: Colors.deepPurpleAccent,
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManagementScreen())),
                  ),
                  _buildDivider(context, isDark),
                  _buildNavRow(
                    context: context,
                    title: context.tr('clinic_stats'),
                    icon: Icons.insights_rounded,
                    color: Colors.teal,
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
                  ),
                ]),

                const SizedBox(height: 36),

                // ── COMING SOON GROUP ────────────────────────────────────────────
                _buildSectionTitle(context, context.tr('coming_soon')),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.4,
                  children: [
                    _buildModernComingSoon(context, context.tr('cloud_backup'), Icons.cloud_sync_outlined, Colors.teal, isDark),
                    _buildModernComingSoon(context, context.tr('ai_assistant'), Icons.auto_awesome_outlined, Colors.amber, isDark),
                    _buildModernComingSoon(context, context.tr('appointments'), Icons.calendar_today_rounded, Colors.indigo, isDark),
                    _buildModernComingSoon(context, context.tr('billing'), Icons.account_balance_wallet_outlined, Colors.deepOrange, isDark),
                  ],
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 20),
      child: Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
    );
  }

  Widget _buildNavRow({required BuildContext context, required String title, required IconData icon, required Color color, required bool isDark, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: isDark ? Colors.deepPurpleAccent : Colors.orangeAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(context.tr('dark_mode'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Switch.adaptive(
            value: isDark,
            activeColor: Colors.deepPurpleAccent,
            onChanged: (val) => ref.read(appSettingsProvider.notifier).toggleTheme(val),
          ),
        ],
      ),
    );
  }

  Widget _buildLangToggle(BuildContext context, WidgetRef ref, String currentLang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.language_rounded, color: Colors.blue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(context.tr('language'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _langBtn('ar', 'عربي', currentLang == 'ar', () => ref.read(appSettingsProvider.notifier).changeLanguage('ar'), isDark),
                _langBtn('en', 'Eng', currentLang == 'en', () => ref.read(appSettingsProvider.notifier).changeLanguage('en'), isDark),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _langBtn(String code, String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white24 : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildModernComingSoon(BuildContext context, String title, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.1)),
        boxShadow: isDark ? [] : [
           BoxShadow(color: color.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -10, top: -10, child: Icon(icon, color: color.withOpacity(0.05), size: 70)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(context.tr('soon_badge'), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
            ),
          ),
        ],
      ),
    );
  }
}
