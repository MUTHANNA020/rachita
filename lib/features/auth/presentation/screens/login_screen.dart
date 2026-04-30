import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rachita/features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 48),
              _buildLoginCard(context, authState),
              const SizedBox(height: 32),
              _buildRegisterRedirect(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
          ),
          child: const Icon(Icons.emergency_rounded, size: 60, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text(
          'RACHITA',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.primary),
        ),
        const Text(
          'CLINICAL INTELLIGENCE',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, AuthState authState) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تسجيل الدخول', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('مرحباً بك في منصة راشيتة الطبية', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 32),
            
            _textField(
              controller: _usernameController,
              label: 'اسم المستخدم',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            _textField(
              controller: _passwordController,
              label: 'كلمة المرور',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: authState.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('دخول آمن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
            
            if (authState.error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.1))),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(authState.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('ليس لديك حساب بعد؟', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          child: const Text('إنشاء حساب عيادة', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _textField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.5), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'أدخل $label...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(_usernameController.text, _passwordController.text);
    }
  }
}
