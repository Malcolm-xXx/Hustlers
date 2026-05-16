import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../models/auth_tokens_model.dart';
import '../models/login_request_model.dart';
import '../models/logout_request_model.dart';
import '../models/otp_request_model.dart';
import '../models/password_reset_verify_otp_request_model.dart';
import '../models/register_request_model.dart';
import '../models/reset_password_request_model.dart';
import '../models/social_login_request_model.dart';
import '../models/user_model.dart';
import '../models/profile_photo_upload_url_model.dart';
import '../models/address_model.dart';
import '../models/address_request_model.dart';
import '../models/device_token_model.dart';
import '../models/device_token_request_model.dart';

class AuthRemoteDatasource {
  final DioClient _dioClient;

  AuthRemoteDatasource(this._dioClient);

  // ───── Registration ─────

  Future<void> register(RegisterRequestModel request) async {
    try {
      await _dioClient.post(
        ApiConstants.register,
        data: request.toJson(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<AuthTokensModel> verifyEmailOtp(OtpRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.verifyEmailOtp,
        data: request.toJson(),
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> resendEmailOtp(String email) async {
    try {
      await _dioClient.post(
        ApiConstants.resendEmailOtp,
        data: {'email': email},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  // ───── Login ─────

  Future<AuthTokensModel> login(LoginRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: request.toJson(),
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<AuthTokensModel> googleLogin(SocialLoginRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.googleLogin,
        data: request.toJson(),
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  // ───── Token management ─────

  Future<String> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.tokenRefresh,
        data: {'refresh_token': refreshToken},
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data['access_token'] as String;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> logout(LogoutRequestModel request) async {
    try {
      await _dioClient.post(
        ApiConstants.logout,
        data: request.toJson(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  // ───── Me ─────

  Future<UserModel> getMe() async {
    try {
      final response = await _dioClient.get(ApiConstants.me);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<UserModel> updateMe(Map<String, dynamic> fields) async {
    try {
      final response = await _dioClient.patch(
        ApiConstants.me,
        data: fields,
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dioClient.delete(ApiConstants.me);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  // ───── Profile Photo ─────

  Future<ProfilePhotoUploadUrlModel> getProfilePhotoUploadUrl() async {
    try {
      final response = await _dioClient.get(ApiConstants.profilePhotoUploadUrl);
      return ProfilePhotoUploadUrlModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> updateProfilePhoto(String publicId) async {
    try {
      await _dioClient.post(
        ApiConstants.profilePhotoUpdate,
        data: {'profile_photo_cloudinary_public_id': publicId},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  // ───── Password Reset (3-step) ─────

  Future<void> forgotPassword(String email) async {
    try {
      await _dioClient.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> resendPasswordOtp(String email) async {
    try {
      await _dioClient.post(
        ApiConstants.resendPasswordOtp,
        data: {'email': email},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<String> verifyPasswordResetOtp(
    PasswordResetVerifyOtpRequestModel request,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.passwordResetVerifyOtp,
        data: request.toJson(),
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data['reset_token'] as String;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> resetPassword(ResetPasswordRequestModel request) async {
    try {
      await _dioClient.post(
        ApiConstants.resetPassword,
        data: request.toJson(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  // ───── Addresses ─────

  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _dioClient.get(ApiConstants.addresses);
      final data = response.data;
      final List<dynamic> results = data is Map<String, dynamic> && data.containsKey('results')
          ? data['results'] as List<dynamic>
          : data as List<dynamic>;
      return results.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<AddressModel> createAddress(AddressRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.addresses,
        data: request.toJson(),
      );
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<AddressModel> getAddress(String addressId) async {
    try {
      final response = await _dioClient.get(ApiConstants.addressDetails(addressId));
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<AddressModel> updateAddress(String addressId, Map<String, dynamic> fields) async {
    try {
      final response = await _dioClient.patch(
        ApiConstants.addressDetails(addressId),
        data: fields,
      );
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _dioClient.delete(ApiConstants.addressDetails(addressId));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  // ───── Device Tokens ─────

  Future<List<DeviceTokenModel>> getDeviceTokens() async {
    try {
      final response = await _dioClient.get(ApiConstants.deviceTokens);
      final data = response.data;
      final List<dynamic> results = data is Map<String, dynamic> && data.containsKey('results')
          ? data['results'] as List<dynamic>
          : data as List<dynamic>;
      return results.map((e) => DeviceTokenModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<DeviceTokenModel> createDeviceToken(DeviceTokenRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.deviceTokens,
        data: request.toJson(),
      );
      return DeviceTokenModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<DeviceTokenModel> getDeviceToken(String tokenId) async {
    try {
      final response = await _dioClient.get(ApiConstants.deviceTokenDetails(tokenId));
      return DeviceTokenModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> deleteDeviceToken(String tokenId) async {
    try {
      await _dioClient.delete(ApiConstants.deviceTokenDetails(tokenId));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
