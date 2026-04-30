import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rachita/shared/theme/app_colors.dart';
import 'package:rachita/features/auth/data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _clinicNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _clinicNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_clinicNameController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('يرجى ملء الحقول الأساسية');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('كلمات المرور غير متطابقة');
      return;
    }

    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);

    try {
      final success = await authRepo.register(
        _clinicNameController.text,
        _fullNameController.text,
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          _showError('فشل إنشاء الحساب. اسم المستخدم قد يكون مستخدماً.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('حدث خطأ: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                   _textField(_clinicNameController, 'اسم العيادة', Icons.business_rounded),
                   const SizedBox(height: 16),
                   _textField(_fullNameController, 'الاسم الكامل للطبيب', Icons.person_rounded),
                   const SizedBox(height: 16),
                   _textField(_licenseController, 'رقم الترخيص الطبي', Icons.badge_rounded),
                   const SizedBox(height: 16),
                   _textField(_usernameController, 'اسم المستخدم المفضل', Icons.alternate_email_rounded),
                   const SizedBox(height: 16),
                   _textField(_passwordController, 'كلمة المرور', Icons.vpn_key_rounded, isPassword: true),
                   const SizedBox(height: 16),
                   _textField(_confirmPasswordController, 'تأكيد كلمة المرور', Icons.check_circle_outline_rounded, isPassword: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تأكيد وإتمام التسجيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background.withOpacity(0.5),
      ),
    );
  }
}
