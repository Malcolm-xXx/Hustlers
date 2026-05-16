import '../entities/auth_tokens_entity.dart';
import '../entities/user_entity.dart';
import '../../data/models/profile_photo_upload_url_model.dart';
import '../entities/address_entity.dart';
import '../entities/device_token_entity.dart';

abstract class IAuthRepository {
  // Registration flow
  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<AuthTokensEntity> verifyEmailOtp({
    required String email,
    required String otp,
  });

  Future<void> resendEmailOtp(String email);

  // Login
  Future<AuthTokensEntity> login({
    required String email,
    required String password,
  });

  Future<AuthTokensEntity> googleLogin({required String idToken});

  // Token management
  Future<String> refreshAccessToken(String refreshToken);

  Future<void> logout({required String refreshToken});

  // Current user
  Future<UserEntity> getMe();

  Future<UserEntity> updateMe(Map<String, dynamic> fields);

  Future<void> deleteAccount();

  // Profile Photo
  Future<ProfilePhotoUploadUrlModel> getProfilePhotoUploadUrl();

  Future<void> updateProfilePhoto(String publicId);

  // Password reset — 3-step flow
  Future<void> forgotPassword(String email);

  Future<void> resendPasswordOtp(String email);

  /// Returns the resetToken needed for [resetPassword].
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  });

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  });

  // Addresses
  Future<List<AddressEntity>> getAddresses();

  Future<AddressEntity> createAddress({
    required String title,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String country,
    bool isDefault = false,
  });

  Future<AddressEntity> getAddress(String addressId);

  Future<AddressEntity> updateAddress(String addressId, Map<String, dynamic> fields);

  Future<void> deleteAddress(String addressId);

  // Device Tokens
  Future<List<DeviceTokenEntity>> getDeviceTokens();

  Future<DeviceTokenEntity> createDeviceToken({
    required String token,
    required String platform,
  });

  Future<DeviceTokenEntity> getDeviceToken(String tokenId);

  Future<void> deleteDeviceToken(String tokenId);
}
