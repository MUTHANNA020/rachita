class DoctorEntity {
  final int? id;
  final String name;
  final String? nameEn;
  final String specialty;
  final String? specialtyEn;
  final String? subSpecialty;
  final String? subSpecialtyEn;
  final String clinicName;
  final String? licenseNumber;
  final String? credentials;
  final String? credentialsEn;
  final String? bio;
  final String? bioEn;
  final String? address;
  final String? phone;
  final String? workingHoursFrom;
  final String? workingHoursTo;
  final String? logoPath;
  final String? signaturePath;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  DoctorEntity({
    this.id,
    required this.name,
    this.nameEn,
    required this.specialty,
    this.specialtyEn,
    this.subSpecialty,
    this.subSpecialtyEn,
    required this.clinicName,
    this.licenseNumber,
    this.credentials,
    this.credentialsEn,
    this.bio,
    this.bioEn,
    this.address,
    this.phone,
    this.workingHoursFrom,
    this.workingHoursTo,
    this.logoPath,
    this.signaturePath,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });
}
