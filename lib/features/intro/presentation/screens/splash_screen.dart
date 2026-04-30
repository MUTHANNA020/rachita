import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rachita/features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _contentSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _mainCtrl.forward();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final primaryColor = isDark ? const Color(0xFF38BDF8) : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background subtle pattern or glow
          if (isDark)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.05),
                ),
              ),
            ),

          Center(
            child: AnimatedBuilder(
              animation: _mainCtrl,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _logoFade,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo - Now with a Pulse Effect
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? primaryColor.withOpacity(0.1) : primaryColor.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.health_and_safety_rounded,
                            size: 80,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Brand Name
                      Text(
                        'RACHITA',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'CLINICAL INTELLIGENCE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Modern loading indicator
                      SizedBox(
                        width: 200,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _mainCtrl.value,
                                minHeight: 4,
                                backgroundColor: isDark ? Colors.white10 : AppColors.primaryLight,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isDark ? 'SYSTEM INITIALIZING...' : 'جاري تهيئة النظام المتكامل...',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white38 : AppColors.textMuted,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Versign information at bottom
          Positioned(
            bottom: 40,
            child: Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: Text(
                'v2.5.0 Premium Edition',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white10 : Colors.black12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
