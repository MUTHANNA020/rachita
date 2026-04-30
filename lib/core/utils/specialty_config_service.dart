class SpecialtyConfig {
  final List<String> enabledVitals;
  final String nameAr;
  final String nameEn;

  SpecialtyConfig({
    required this.enabledVitals,
    this.nameAr = '',
    this.nameEn = '',
  });
}

class SpecialtyConfigService {
  static SpecialtyConfig getConfigForSpecialty(String specialty) {
    if (specialty.isEmpty) return _getDefaultConfig();
    
    final s = specialty.toLowerCase();
    
    // Pediatrician / طب الأطفال
    if (s.contains('pediatric') || s.contains('أطفال')) {
      return SpecialtyConfig(
        enabledVitals: ['weight', 'height', 'head_circ', 'temperature', 'bmi'],
        nameAr: 'طب الأطفال',
        nameEn: 'Pediatrics',
      );
    }
    
    // Ophthalmologist / طب العيون
    if (s.contains('ophthalmol') || s.contains('عيون')) {
      return SpecialtyConfig(
        enabledVitals: ['va', 'iop', 'sugar', 'systolic'],
        nameAr: 'طب العيون',
        nameEn: 'Ophthalmology',
      );
    }
    
    // Cardiology / طب القلب
    if (s.contains('cardio') || s.contains('قلب')) {
      return SpecialtyConfig(
        enabledVitals: ['systolic', 'pulse', 'weight', 'bmi'],
        nameAr: 'طب القلب',
        nameEn: 'Cardiology',
      );
    }
    
    // Dentist / طب الأسنان
    if (s.contains('dentist') || s.contains('أسنان')) {
      return SpecialtyConfig(
        enabledVitals: ['sugar', 'systolic', 'temperature'],
        nameAr: 'طب الأسنان',
        nameEn: 'Dentistry',
      );
    }

    // Orthopedic / طب العظام
    if (s.contains('ortho') || s.contains('عظام')) {
      return SpecialtyConfig(
        enabledVitals: ['weight', 'bmi', 'systolic', 'height'],
        nameAr: 'طب العظام',
        nameEn: 'Orthopedics',
      );
    }

    // Ear, Nose, Throat / أنف وأذن وحنجرة
    if (s.contains('ent') || (s.contains('أنف') && s.contains('حنجرة'))) {
      return SpecialtyConfig(
        enabledVitals: ['temperature', 'pulse', 'systolic'],
        nameAr: 'أنف وأذن وحنجرة',
        nameEn: 'ENT',
      );
    }

    // Default (General / Internist / others)
    return _getDefaultConfig();
  }

  static SpecialtyConfig _getDefaultConfig() {
    return SpecialtyConfig(
      enabledVitals: ['weight', 'systolic', 'sugar', 'pulse'],
      nameAr: 'طب عام',
      nameEn: 'General Practice',
    );
  }
}
