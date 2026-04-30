import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rachita/shared/providers/app_settings_provider.dart';
import 'package:rachita/shared/theme/app_colors.dart';
import 'package:rachita/features/doctor/presentation/providers/doctor_provider.dart';
import 'package:rachita/features/patient/presentation/providers/patient_provider.dart';
import 'package:rachita/features/prescription/presentation/providers/prescription_provider.dart';
import 'package:rachita/core/services/sync_service.dart';
import 'package:rachita/core/database/database_helper.dart';

class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState
    extends ConsumerState<AccountManagementScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = prefs.getString('username') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
    });
  }

  Future<void> _saveUserData() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('user_email', _emailController.text);

    if (mounted) {
      setState(() => _isEditMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث بيانات الحساب بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorAsync = ref.watch(doctorProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: -30,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  _buildHeaderContent(prefs, doctorAsync),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => _isEditMode = !_isEditMode),
                icon: Icon(_isEditMode ? Icons.close : Icons.edit_note_rounded),
                color: Colors.white,
                tooltip: _isEditMode ? 'إلغاء' : 'تعديل البيانات',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'نظرة عامة على البيانات',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        'المرضى',
                        ref.watch(globalPatientCountProvider).when(
                          data: (count) => count.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        Icons.people_alt_rounded,
                        Colors.blue,
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'الوصفات',
                        ref.watch(globalPrescriptionCountProvider).when(
                          data: (count) => count.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        Icons.description_rounded,
                        Colors.orange,
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'المزامنة',
                        '100%',
                        Icons.cloud_done_rounded,
                        Colors.green,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle('إعدادات الحساب والأمان', Icons.security_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildAccountSettingsCard(isDark),
                  const SizedBox(height: 32),
                  _buildSectionTitle('هوية العيادة المهنية', Icons.business_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildClinicIdentityCard(doctorAsync, isDark),
                  const SizedBox(height: 40),
                  _buildActionButtons(context),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(SharedPreferences prefs, AsyncValue<dynamic> doctorAsync) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Hero(
            tag: 'profile_pic',
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white24, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            prefs.getString('username') ?? 'طبيب رشيدة',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prefs.getString('clinic_name') ?? 'عيادة رشيدة الذكية',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.border.withOpacity(0.5),
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white70 : AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettingsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildPremiumField(_usernameController, 'اسم المستخدم', Icons.alternate_email_rounded, isDark),
          const SizedBox(height: 16),
          _buildPremiumField(_emailController, 'البريد الإلكتروني للهوية', Icons.email_outlined, isDark),
          if (_isEditMode) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text('حفظ التعديلات الجديدة', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicIdentityCard(AsyncValue<dynamic> doctorAsync, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.border.withOpacity(0.5)),
      ),
      child: doctorAsync.when(
        data: (doctor) => doctor != null ? Column(
          children: [
            _buildInfoTile('الاسم المهني', doctor.name, Icons.badge_outlined, isDark),
            const Divider(height: 24),
            _buildInfoTile('التخصص السريري', doctor.specialty, Icons.medical_services_outlined, isDark),
            const Divider(height: 24),
            _buildInfoTile('رقم الترخيص', doctor.licenseNumber ?? 'غير مسجل', Icons.verified_user_outlined, isDark),
            const Divider(height: 24),
            _buildInfoTile('العنوان الموثق', doctor.address ?? 'غير محدد', Icons.location_on_outlined, isDark),
          ],
        ) : _buildEmptyDoctorState(isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('حدث خطأ في مزامنة بيانات العيادة'),
      ),
    );
  }

  Widget _buildEmptyDoctorState(bool isDark) {
    return Column(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300, size: 40),
        const SizedBox(height: 12),
        const Text('لم يتم إعداد الملف الشخصي الطبي بالكامل'),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/home'), // Focus on profile tab

          child: const Text('إعداد الآن'),
        )
      ],
    );
  }

  Widget _buildPremiumField(TextEditingController controller, String label, IconData icon, bool isDark) {
    return TextField(
      controller: controller,
      enabled: _isEditMode,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: isDark ? Colors.black26 : AppColors.primaryLight.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildLargeActionButton(
          'مزامنة البيانات والحساب الآن',
          Icons.sync_rounded,
          AppColors.primary,
          () => _handleFullSync(context),
        ),
        const SizedBox(height: 16),
        _buildLargeActionButton(
          'تسجيل الخروج من الحساب',
          Icons.logout_rounded,
          Colors.orange.shade700,
          () => _confirmLogout(context),
        ),
        const SizedBox(height: 16),
        _buildLargeActionButton(
          'حذف كافة البيانات من الجهاز',
          Icons.delete_forever_rounded,
          AppColors.error,
          () => _confirmFactoryReset(context),
          isOutline: true,
        ),
      ],
    );
  }

  Widget _buildLargeActionButton(String label, IconData icon, Color color, VoidCallback onTap, {bool isOutline = false}) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: isOutline
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 22),
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 22, color: Colors.white),
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
    );
  }

  Future<void> _handleFullSync(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('بدء المزامنة الشاملة للحساب والبيانات...')),
    );
    try {
      await ref.read(syncServiceProvider).runFullSync();
      if (context.mounted) {
        ref.invalidate(globalPatientCountProvider);
        ref.invalidate(globalPrescriptionCountProvider);
        ref.invalidate(doctorProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تمت المزامنة بنجاح واسترجعت كافة البيانات'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشلت المزامنة: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟ سيتم إغلاق الجلسة الحالية وتأمين البيانات.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final prefs = ref.read(sharedPreferencesProvider);
              await DatabaseHelper.instance.resetDb(shouldDelete: false);
              await prefs.remove('auth_token');
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
            child: const Text('خروج آمن'),
          ),
        ],
      ),
    );
  }

  void _confirmFactoryReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ حذف نهائي للبيانات'),
        content: const Text('سيتم حذف كافة البيانات المحلية (المرضى، الوصفات، ملف الطبيب) نهائياً من هذا الجهاز. هل تود الاستمرار؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(doctorProvider.notifier).resetApp();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('تأكيد الحذف النهائي'),
          ),
        ],
      ),
    );
  }
}
