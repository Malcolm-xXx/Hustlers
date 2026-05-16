import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/dio_provider.dart';

final usersRemoteDatasourceProvider = Provider<UsersRemoteDatasource>(
  (ref) => UsersRemoteDatasource(ref.watch(dioClientProvider)),
);

class UsersRemoteDatasource {
  final DioClient _client;
  UsersRemoteDatasource(this._client);

  /// POST /api/v1/users/onboard
  /// Saves the user's onboarding location/address data.
  Future<void> onboardUser({
    String? formattedAddress,
    double? latitude,
    double? longitude,
    bool? isDefault,
    Map<String, dynamic>? onboardingData,
  }) async {
    try {
      await _client.post(
        ApiConstants.usersOnboard,
        data: {
          if (formattedAddress != null) 'formatted_address': formattedAddress,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (isDefault != null) 'is_default': isDefault,
          if (onboardingData != null) ...onboardingData,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  /// DELETE /api/v1/users/me/profile-image
  Future<void> deleteProfileImage() async {
    try {
      await _client.delete(ApiConstants.usersMeProfileImage);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  /// DELETE /api/v1/users/me/banner-image
  Future<void> deleteBannerImage() async {
    try {
      await _client.delete(ApiConstants.usersMeBannerImage);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
