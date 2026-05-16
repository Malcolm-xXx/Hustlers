class UserEntity {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String? profilePhotoUrl;
  final String? profilePhotoCloudinaryPublicId;
  final bool isVerified;
  final bool isOnboarded;
  final Map<String, dynamic>? onboardingData;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.profilePhotoUrl,
    this.profilePhotoCloudinaryPublicId,
    required this.isVerified,
    this.isOnboarded = false,
    this.onboardingData,
  });
}
