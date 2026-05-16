import '../../domain/entities/user_entity.dart';

class UserModel {
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

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.profilePhotoUrl,
    this.profilePhotoCloudinaryPublicId,
    required this.isVerified,
    required this.isOnboarded,
    this.onboardingData,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      role: json['role'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      profilePhotoCloudinaryPublicId:
          json['profile_photo_cloudinary_public_id'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
      onboardingData: json['onboarding_data'] as Map<String, dynamic>?,
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        profilePhotoUrl: profilePhotoUrl,
        profilePhotoCloudinaryPublicId: profilePhotoCloudinaryPublicId,
        isVerified: isVerified,
        isOnboarded: isOnboarded,
        onboardingData: onboardingData,
      );
}
