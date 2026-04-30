import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/doctor_entity.dart';
import '../providers/doctor_provider.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/localization/app_localizations.dart';
import '../../../../core/utils/clinical_logic.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _specialtyEnController = TextEditingController();
  final _clinicController = TextEditingController();
  final _licenseController = TextEditingController();
  final _credentialsController = TextEditingController();
  final _credentialsEnController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hoursFromController = TextEditingController();
  final _hoursToController = TextEditingController();
  final _bioController = TextEditingController();
  final _bioEnController = TextEditingController();
  
  String? _logoPath;
  String? _signaturePath;
  String? _photoPath;
  
  bool _isInitialized = false;
  bool _isEditMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _specialtyController.dispose();
    _specialtyEnController.dispose();
    _clinicController.dispose();
    _licenseController.dispose();
    _credentialsController.dispose();
    _credentialsEnController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _hoursFromController.dispose();
    _hoursToController.dispose();
    _bioController.dispose();
    _bioEnController.dispose();
    super.dispose();
  }

  bool _isValidImage(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('data:image') || path.startsWith('http')) return true;
    if (!kIsWeb) return File(path).existsSync();
    return true; 
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('data:image')) {
      return MemoryImage(base64Decode(path.split(',').last));
    } else if (path.startsWith('http') || kIsWeb) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  Future<void> _pickImage(int type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        if (type == 0) {
          _logoPath = base64String;
        } else if (type == 1) {
          _signaturePath = base64String;
        } else {
          _photoPath = base64String;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final currentDoctor = ref.read(doctorProvider).value;

    final newDoctor = DoctorEntity(
      id: currentDoctor?.id,
      name: _nameController.text,
      nameEn: _nameEnController.text.isEmpty ? null : _nameEnController.text,
      specialty: _specialtyController.text,
      specialtyEn: _specialtyEnController.text.isEmpty ? null : _specialtyEnController.text,
      clinicName: _clinicController.text,
      licenseNumber: _licenseController.text.isEmpty ? null : _licenseController.text,
      credentials: _credentialsController.text.isEmpty ? null : _credentialsController.text,
      credentialsEn: _credentialsEnController.text.isEmpty ? null : _credentialsEnController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      workingHoursFrom: _hoursFromController.text,
      workingHoursTo: _hoursToController.text,
      bio: _bioController.text,
      bioEn: _bioEnController.text,
      logoPath: _logoPath,
      signaturePath: _signaturePath,
      photoPath: _photoPath,
      createdAt: currentDoctor?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(doctorProvider.notifier).saveProfile(newDoctor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('save_success'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isEditMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('save_error')} $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorProvider);

    return LoadingOverlay(
      isLoading: doctorAsync.isLoading,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: doctorAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('${context.tr('stats_error')} $err')),
          data: (doctor) {
            final shouldShowEdit = _isEditMode || doctor == null;

            if (!_isInitialized && doctor != null) {
              _nameController.text = doctor.name;
              _nameEnController.text = doctor.nameEn ?? '';
              _specialtyController.text = doctor.specialty;
              _specialtyEnController.text = doctor.specialtyEn ?? '';
              _clinicController.text = doctor.clinicName;
              _licenseController.text = doctor.licenseNumber ?? '';
              _credentialsController.text = doctor.credentials ?? '';
              _credentialsEnController.text = doctor.credentialsEn ?? '';
              _addressController.text = doctor.address ?? '';
              _phoneController.text = doctor.phone ?? '';
              _hoursFromController.text = doctor.workingHoursFrom ?? '';
              _hoursToController.text = doctor.workingHoursTo ?? '';
              _bioController.text = doctor.bio ?? '';
              _bioEnController.text = doctor.bioEn ?? '';
              _logoPath = doctor.logoPath;
              _signaturePath = doctor.signaturePath;
              _photoPath = doctor.photoPath;
              _isInitialized = true;
            }

            if (shouldShowEdit) {
              return _buildEditMode();
            } else {
              return _buildViewMode(doctor);
            }
          },
        ),
        floatingActionButton: doctorAsync.value != null && !_isEditMode
            ? FloatingActionButton.extended(
                onPressed: () => setState(() => _isEditMode = true),
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                label: Text(context.tr('edit_profile'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.primary,
                elevation: 4,
              )
            : null,
      ),
    );
  }

  Widget _buildViewMode(DoctorEntity doctor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Elegant Header Profile
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, bottom: 30, left: 24, right: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              boxShadow: isDark ? [] : [const BoxShadow(color: Color(0x0A000000), blurRadius: 15, offset: Offset(0, 5))],
            ),
            child: Column(
              children: [
                if (_isValidImage(doctor.photoPath))
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2)],
                      image: DecorationImage(
                        image: _getImageProvider(doctor.photoPath!),
                        fit: BoxFit.cover
                      ),
                    ),
                  )
                else
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
                    ),
                    child: const Icon(Icons.person_rounded, size: 60, color: AppColors.primary),
                  ),
                const SizedBox(height: 20),
                Text('${context.tr('doctor_title')}${doctor.name}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(doctor.specialty, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                if (doctor.credentials != null && doctor.credentials!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    doctor.credentials!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color, fontStyle: FontStyle.italic),
                  ),
                ],
                if (doctor.licenseNumber != null && doctor.licenseNumber!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text('${context.tr('license_number')}: ${doctor.licenseNumber}',
                          style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildInfoCard(Icons.local_hospital_rounded, context.tr('clinic_or_center'), doctor.clinicName),
                const SizedBox(height: 12),
                if (doctor.phone != null && doctor.phone!.isNotEmpty) ...[
                  _buildInfoCard(Icons.phone_rounded, context.tr('contact_phone'), doctor.phone!),
                  const SizedBox(height: 12),
                ],
                if (doctor.address != null && doctor.address!.isNotEmpty) ...[
                  _buildInfoCard(Icons.location_on_rounded, context.tr('address'), doctor.address!),
                  const SizedBox(height: 12),
                ],
                if (doctor.workingHoursFrom != null && doctor.workingHoursTo != null && doctor.workingHoursFrom!.isNotEmpty) ...[
                  _buildInfoCard(Icons.access_time_rounded, context.tr('working_hours'), '${doctor.workingHoursFrom} - ${doctor.workingHoursTo}'),
                  const SizedBox(height: 12),
                ],
                if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                  _buildInfoCard(Icons.info_outline_rounded, context.tr('doctor_bio'), doctor.bio!),
                  const SizedBox(height: 12),
                ],

                if (_isValidImage(doctor.signaturePath)) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(context.tr('stamp_and_signature'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Image(image: _getImageProvider(doctor.signaturePath!), fit: BoxFit.contain),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.3 : 0.1)),
        boxShadow: isDark ? [] : [const BoxShadow(color: Color(0x02000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr('edit_personal_info'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                if (ref.read(doctorProvider).value != null)
                  IconButton(
                    onPressed: () => setState(() => _isEditMode = false),
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).textTheme.bodyMedium?.color),
                    style: IconButton.styleFrom(backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
              ],
            ),
            Column(
            children: [
              _buildSectionHeader(Icons.language_rounded, context.tr('personal_info')),
              const SizedBox(height: 16),
              // Arabic Section
              _buildSubsectionTitle('العربية'),
              _buildTextField(_nameController, context.tr('doctor_full_name'), Icons.person_outline, true),
              const SizedBox(height: 16),
              _buildSpecialtyDropdown(),
              const SizedBox(height: 16),
              _buildTextField(_specialtyEnController, context.tr('specialty_en'), Icons.language_rounded, false, readOnly: true),
              const SizedBox(height: 24),
              
              // English Section
              _buildSubsectionTitle('English'),
              _buildTextField(_nameEnController, context.tr('doctor_name_en'), Icons.person_outline, false),
              const SizedBox(height: 16),
              _buildTextField(_specialtyEnController, context.tr('specialty_en'), Icons.medical_services_outlined, false),
              const SizedBox(height: 16),
              _buildTextField(_credentialsEnController, context.tr('credentials_en'), Icons.school_outlined, false),
              const SizedBox(height: 16),
              _buildTextField(_bioController, "${context.tr('doctor_bio')} (Ar)", Icons.description_outlined, false, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(_bioEnController, "${context.tr('doctor_bio')} (En)", Icons.description_outlined, false, maxLines: 3),
              const SizedBox(height: 32),

              _buildSectionHeader(Icons.local_hospital_rounded, context.tr('clinic_or_center')),
              const SizedBox(height: 16),
              _buildTextField(_clinicController, context.tr('clinic_name'), Icons.local_hospital_outlined, true),
              const SizedBox(height: 16),
              _buildTextField(_licenseController, context.tr('license_number'), Icons.verified_outlined, false),
            ],
          ),
            
            const SizedBox(height: 32),
            _buildSectionHeader(Icons.contact_mail_rounded, context.tr('contact_info')),
            const SizedBox(height: 20),
            _buildTextField(_addressController, context.tr('full_address'), Icons.location_on_outlined, false),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, context.tr('main_phone'), Icons.phone_outlined, false, type: TextInputType.phone),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_hoursFromController, context.tr('hours_from'), Icons.access_time_rounded, false)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_hoursToController, context.tr('hours_to'), Icons.access_time_rounded, false)),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionHeader(Icons.image_outlined, context.tr('identity_and_stamp')),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _ImagePickerBox(
                    context: context,
                    label: context.tr('personal_photo'),
                    path: _photoPath,
                    onTap: () => _pickImage(2),
                  ),
                  _ImagePickerBox(
                    context: context,
                    label: context.tr('clinic_logo'),
                    path: _logoPath,
                    onTap: () => _pickImage(0),
                  ),
                  _ImagePickerBox(
                    context: context,
                    label: context.tr('personal_stamp'),
                    path: _signaturePath,
                    onTap: () => _pickImage(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(context.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        const SizedBox(width: 8),
        Expanded(child: Divider(thickness: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const Expanded(child: Divider(indent: 8)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool required, {int maxLines = 1, TextInputType? type, bool readOnly = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: type,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(readOnly ? 0.6 : 1.0),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
        hintStyle: const TextStyle(fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.3 : 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
      validator: required ? (value) => value == null || value.isEmpty ? context.tr('required_field') : null : null,
    );
  }

  Widget _buildSpecialtyDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentVal = _specialtyController.text.trim();
    
    // Safety Check: Ensure the value exists in the specialties list to avoid Flutter assertion crash
    final bool valueExists = ClinicalLogic.specialties.any((element) => element.nameAr == currentVal);
    final String? validatedValue = valueExists ? currentVal : (currentVal.isEmpty ? null : null);

    return DropdownButtonFormField<String>(
      value: validatedValue,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _specialtyController.text = value;
            final spec = ClinicalLogic.specialties.firstWhere((s) => s.nameAr == value);
            _specialtyEnController.text = spec.nameEn;
          });
        }
      },
      items: ClinicalLogic.specialties.map((s) {
        return DropdownMenuItem<String>(
          value: s.nameAr,
          child: Row(
            children: [
              Icon(s.icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(s.nameAr),
            ],
          ),
        );
      }).toList(),
      // If the value doesn't exist, we add a dummy item to prevent the crash while letting the user re-select
      // items: valueExists ? ... : [DropdownMenuItem(value: currentVal, child: Text(currentVal)), ...],
      decoration: InputDecoration(
        labelText: context.tr('medical_specialty'),
        prefixIcon: const Icon(Icons.medical_services_outlined, size: 20, color: AppColors.primary),
        hintText: !valueExists && currentVal.isNotEmpty ? currentVal : null,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.3 : 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
      validator: (value) => value == null || value.isEmpty ? context.tr('required_field') : null,
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String? path;
  final VoidCallback onTap;

  const _ImagePickerBox({required this.context, required this.label, required this.path, required this.onTap});

  @override
  Widget build(BuildContext _) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(isDark ? 0.3 : 0.1)),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: path != null && path!.isNotEmpty && (path!.startsWith('data:image') || path!.startsWith('http') || (!kIsWeb && File(path!).existsSync()))
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: path!.startsWith('data:image') 
                        ? Image.memory(base64Decode(path!.split(',').last), fit: BoxFit.cover)
                        : (kIsWeb || path!.startsWith('http') 
                            ? Image.network(path!, fit: BoxFit.cover)
                            : Image.file(File(path!), fit: BoxFit.cover)),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 28, color: AppColors.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 4),
                      Text(context.tr('choose_image'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
