import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rachita/shared/theme/app_theme.dart';
import 'package:rachita/shared/theme/app_colors.dart';
import 'package:rachita/shared/localization/app_localizations.dart';
import 'package:rachita/shared/providers/app_settings_provider.dart';
import 'package:rachita/features/auth/presentation/providers/auth_provider.dart';
import 'package:rachita/core/database/database_helper.dart';
import 'package:rachita/core/security/security_wrapper.dart';
import 'package:rachita/features/intro/presentation/screens/splash_screen.dart';
import 'package:rachita/features/auth/presentation/screens/login_screen.dart';
import 'package:rachita/features/auth/presentation/screens/register_screen.dart';
import 'package:rachita/features/dashboard/presentation/screens/clinic_dashboard_screen.dart';
import 'package:rachita/features/patient/presentation/screens/patient_list_screen.dart';
import 'package:rachita/features/prescription/presentation/screens/new_prescription_screen.dart';
import 'package:rachita/features/settings/presentation/screens/settings_screen.dart';
import 'package:rachita/features/sync/presentation/screens/sync_and_backup_screen.dart';
import 'package:rachita/features/account/presentation/screens/account_management_screen.dart';
import 'package:rachita/shared/widgets/responsive_wrapper.dart';
import 'package:rachita/shared/providers/navigation_provider.dart';
import 'package:animations/animations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final results = await Future.wait([
    DatabaseHelper.instance.database,
    SharedPreferences.getInstance(),
  ]);

  final prefs = results[1] as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      title: 'Rachita Smart Clinic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      locale: settings.locale,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const SecurityWrapper(child: MainNavigationScreen()));
          case '/sync':
            return MaterialPageRoute(builder: (_) => const SecurityWrapper(child: SyncAndBackupScreen()));
          case '/account':
            return MaterialPageRoute(builder: (_) => const SecurityWrapper(child: AccountManagementScreen()));
          case '/new_prescription':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(builder: (_) => SecurityWrapper(child: NewPrescriptionScreen(patientId: args?['patientId'] ?? 0)));
          default:
            return null;
        }
      },
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final List<Widget> _screens = [
    const ClinicDashboardScreen(),
    const PatientListScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool showSidebar = !ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          if (showSidebar) _buildSidebar(context),
          Expanded(
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: _buildClinicalAppBar(context),
              ),
              body: PageTransitionSwitcher(
                transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                  return FadeThroughTransition(
                    animation: primaryAnimation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  );
                },
                child: Container(
                  key: ValueKey<int>(ref.watch(navigationIndexProvider)),
                  child: _screens[ref.watch(navigationIndexProvider)],
                ),
              ),
              bottomNavigationBar: showSidebar ? null : _buildClinicalBottomBar(context, ref.watch(navigationIndexProvider)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
           right: Directionality.of(context) == TextDirection.ltr ? BorderSide(color: Theme.of(context).dividerColor) : BorderSide.none,
           left: Directionality.of(context) == TextDirection.rtl ? BorderSide(color: Theme.of(context).dividerColor) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: 50),
           _sidebarItem(0, Icons.dashboard_rounded, context.tr('dashboard')),
          _sidebarItem(1, Icons.people_rounded, context.tr('patients')),
          _sidebarItem(2, Icons.settings_rounded, context.tr('settings')),
          const Spacer(),
          _buildUserBrief(),
          const SizedBox(height: 24),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.emergency_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RACHITA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary, letterSpacing: 1)),
            Text('CLINICAL PRO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.secondary, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    final isSelected = ref.watch(navigationIndexProvider) == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => ref.read(navigationIndexProvider.notifier).state = index,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white.withOpacity(0.1) : AppColors.primaryLight) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white54 : AppColors.textSecondary), size: 22),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white54 : AppColors.textSecondary), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBrief() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('welcome_doctor'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 13)), Text(context.tr('admin_role'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 11))])),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      onTap: () {
        ref.read(authProvider.notifier).logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      },
      leading: const Icon(Icons.logout_rounded, color: AppColors.error),
      title: Text(context.tr('logout'), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildClinicalAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('app_title'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(ref.watch(navigationIndexProvider) == 0 ? context.tr('dashboard') : ref.watch(navigationIndexProvider) == 1 ? context.tr('patients') : context.tr('settings'), 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none_rounded, color: Theme.of(context).textTheme.bodyMedium?.color)),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildClinicalBottomBar(BuildContext context, int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 70 + bottomPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
      ),
      child: Stack(
        children: [
          // Glass Background Layer
          ClipRect(
            child: BackdropFilter(
              filter: ColorFilter.mode(
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                BlendMode.srcOver,
              ),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Floating Bar Container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2633) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navbarItem(0, Icons.medication_rounded, context.tr('prescriptions'), currentIndex == 0),
                  _navbarItem(1, Icons.people_alt_rounded, context.tr('patients'), currentIndex == 1),
                  _navbarItem(2, Icons.settings_suggest_rounded, context.tr('settings'), currentIndex == 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navbarItem(int index, IconData icon, String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(navigationIndexProvider.notifier).state = index,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator Dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                width: isSelected ? 20 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              
              // Icon with Scale and Color Transition
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      icon,
                      size: 24,
                      color: isSelected 
                        ? AppColors.primary 
                        : (isDark ? Colors.white54 : AppColors.textSecondary.withOpacity(0.5)),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 2),
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected 
                    ? AppColors.primary 
                    : (isDark ? Colors.white54 : AppColors.textSecondary.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
