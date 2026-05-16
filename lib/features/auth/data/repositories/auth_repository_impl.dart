import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/entities/device_token_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';
import '../models/logout_request_model.dart';
import '../models/otp_request_model.dart';
import '../models/password_reset_verify_otp_request_model.dart';
import '../models/register_request_model.dart';
import '../models/reset_password_request_model.dart';
import '../models/social_login_request_model.dart';
import '../models/address_request_model.dart';
import '../models/device_token_request_model.dart';
import '../models/profile_photo_upload_url_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  // ───── Registration ─────

  @override
  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) =>
      _datasource.register(
        RegisterRequestModel(
          fullName: fullName,
          phoneNumber: phoneNumber,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
        ),
      );

  @override
  Future<AuthTokensEntity> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final model = await _datasource.verifyEmailOtp(OtpRequestModel(email: email, otp: otp));
    return model.toEntity();
  }

  @override
  Future<void> resendEmailOtp(String email) =>
      _datasource.resendEmailOtp(email);

  // ───── Login ─────

  @override
  Future<AuthTokensEntity> login({
    required String email,
    required String password,
  }) async {
    final model = await _datasource
        .login(LoginRequestModel(email: email, password: password));
    return model.toEntity();
  }

  @override
  Future<AuthTokensEntity> googleLogin({required String idToken}) async {
    final model = await _datasource.googleLogin(SocialLoginRequestModel(idToken: idToken));
    return model.toEntity();
  }

  // ───── Token management ─────

  @override
  Future<String> refreshAccessToken(String refreshToken) =>
      _datasource.refreshAccessToken(refreshToken);

  @override
  Future<void> logout({required String refreshToken}) =>
      _datasource.logout(LogoutRequestModel(refreshToken: refreshToken));

  // ───── Me ─────

  @override
  Future<UserEntity> getMe() async {
    final model = await _datasource.getMe();
    return model.toEntity();
  }

  @override
  Future<UserEntity> updateMe(Map<String, dynamic> fields) async {
    final model = await _datasource.updateMe(fields);
    return model.toEntity();
  }

  @override
  Future<void> deleteAccount() => _datasource.deleteAccount();

  // ───── Profile Photo ─────

  @override
  Future<ProfilePhotoUploadUrlModel> getProfilePhotoUploadUrl() =>
      _datasource.getProfilePhotoUploadUrl();

  @override
  Future<void> updateProfilePhoto(String publicId) =>
      _datasource.updateProfilePhoto(publicId);

  // ───── Password Reset ─────

  @override
  Future<void> forgotPassword(String email) => _datasource.forgotPassword(email);

  @override
  Future<void> resendPasswordOtp(String email) => _datasource.resendPasswordOtp(email);

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) =>
      _datasource.verifyPasswordResetOtp(
        PasswordResetVerifyOtpRequestModel(email: email, otp: otp),
      );

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _datasource.resetPassword(
        ResetPasswordRequestModel(
          resetToken: resetToken,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );

  // ───── Addresses ─────

  @override
  Future<List<AddressEntity>> getAddresses() async {
    final models = await _datasource.getAddresses();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<AddressEntity> createAddress({
    required String title,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String country,
    bool isDefault = false,
  }) async {
    final model = await _datasource.createAddress(
      AddressRequestModel(
        title: title,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        country: country,
        isDefault: isDefault,
      ),
    );
    return model.toEntity();
  }

  @override
  Future<AddressEntity> getAddress(String addressId) async {
    final model = await _datasource.getAddress(addressId);
    return model.toEntity();
  }

  @override
  Future<AddressEntity> updateAddress(String addressId, Map<String, dynamic> fields) async {
    final model = await _datasource.updateAddress(addressId, fields);
    return model.toEntity();
  }

  @override
  Future<void> deleteAddress(String addressId) => _datasource.deleteAddress(addressId);

  // ───── Device Tokens ─────

  @override
  Future<List<DeviceTokenEntity>> getDeviceTokens() async {
    final models = await _datasource.getDeviceTokens();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<DeviceTokenEntity> createDeviceToken({
    required String token,
    required String platform,
  }) async {
    final model = await _datasource.createDeviceToken(
      DeviceTokenRequestModel(
        token: token,
        platform: platform,
      ),
    );
    return model.toEntity();
  }

  @override
  Future<DeviceTokenEntity> getDeviceToken(String tokenId) async {
    final model = await _datasource.getDeviceToken(tokenId);
    return model.toEntity();
  }

  @override
  Future<void> deleteDeviceToken(String tokenId) => _datasource.deleteDeviceToken(tokenId);
}
