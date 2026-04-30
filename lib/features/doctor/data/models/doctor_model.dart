import '../../domain/entities/doctor_entity.dart';
import '../../../../core/utils/map_utils.dart';

class DoctorModel extends DoctorEntity {
  DoctorModel({
    super.id,
    required super.name,
    super.nameEn,
    required super.specialty,
    super.specialtyEn,
    super.subSpecialty,
    super.subSpecialtyEn,
    required super.clinicName,
    super.licenseNumber,
    super.credentials,
    super.credentialsEn,
    super.bio,
    super.bioEn,
    super.address,
    super.phone,
    super.workingHoursFrom,
    super.workingHoursTo,
    super.logoPath,
    super.signaturePath,
    super.photoPath,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    final createdAt = SafeMap.getDateTime(map, 'created_at') ?? 
                      SafeMap.getDateTime(map, 'CreatedAt') ?? 
                      DateTime.now();

    // Handle ID (ignore GUID string, keep local int null)
    final idVal = SafeMap.get(map, 'id');
    int? localId = idVal is int ? idVal : null;

    return DoctorModel(
      id: localId,
      name: SafeMap.getString(map, 'name', defaultValue: 'طبيب'),
      nameEn: SafeMap.getString(map, 'name_en'),
      specialty: SafeMap.getString(map, 'specialty', defaultValue: 'عام'),
      specialtyEn: SafeMap.getString(map, 'specialty_en'),
      subSpecialty: SafeMap.getString(map, 'sub_specialty'),
      subSpecialtyEn: SafeMap.getString(map, 'sub_specialty_en'),
      clinicName: SafeMap.getString(map, 'clinic_name', defaultValue: 'عيادة'),
      licenseNumber: SafeMap.getString(map, 'license_number'),
      credentials: SafeMap.getString(map, 'credentials'),
      credentialsEn: SafeMap.getString(map, 'credentials_en'),
      bio: SafeMap.getString(map, 'bio'),
      bioEn: SafeMap.getString(map, 'bio_en'),
      address: SafeMap.getString(map, 'address'),
      phone: SafeMap.getString(map, 'phone'),
      workingHoursFrom: SafeMap.getString(map, 'working_hours_from'),
      workingHoursTo: SafeMap.getString(map, 'working_hours_to'),
      logoPath: SafeMap.get(map, 'logo_path')?.toString(),
      signaturePath: SafeMap.get(map, 'signature_path')?.toString(),
      photoPath: SafeMap.get(map, 'photo_path')?.toString(),
      createdAt: createdAt,
      updatedAt: SafeMap.getDateTime(map, 'updated_at') ?? 
                 SafeMap.getDateTime(map, 'UpdatedAt') ?? 
                 createdAt,
      isSynced: (SafeMap.get(map, 'is_synced') == 1 || SafeMap.get(map, 'is_synced') == true || SafeMap.get(map, 'IsSynced') == true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (nameEn != null) 'name_en': nameEn,
      'specialty': specialty,
      if (specialtyEn != null) 'specialty_en': specialtyEn,
      if (subSpecialty != null) 'sub_specialty': subSpecialty,
      if (subSpecialtyEn != null) 'sub_specialty_en': subSpecialtyEn,
      'clinic_name': clinicName,
      'license_number': licenseNumber,
      'credentials': credentials,
      if (credentialsEn != null) 'credentials_en': credentialsEn,
      'bio': bio,
      if (bioEn != null) 'bio_en': bioEn,
      'address': address,
      'phone': phone,
      'working_hours_from': workingHoursFrom,
      'working_hours_to': workingHoursTo,
      'logo_path': logoPath,
      'signature_path': signaturePath,
      'photo_path': photoPath,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DoctorModel.fromEntity(DoctorEntity entity) {
    return DoctorModel(
      id: entity.id,
      name: entity.name,
      nameEn: entity.nameEn,
      specialty: entity.specialty,
      specialtyEn: entity.specialtyEn,
      subSpecialty: entity.subSpecialty,
      subSpecialtyEn: entity.subSpecialtyEn,
      clinicName: entity.clinicName,
      licenseNumber: entity.licenseNumber,
      credentials: entity.credentials,
      credentialsEn: entity.credentialsEn,
      bio: entity.bio,
      bioEn: entity.bioEn,
      address: entity.address,
      phone: entity.phone,
      workingHoursFrom: entity.workingHoursFrom,
      workingHoursTo: entity.workingHoursTo,
      logoPath: entity.logoPath,
      signaturePath: entity.signaturePath,
      photoPath: entity.photoPath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
    );
  }
}
