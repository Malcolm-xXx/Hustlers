import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';

class OnboardingRemoteDatasource {
  final DioClient _dioClient;

  OnboardingRemoteDatasource(this._dioClient);

  Future<void> completeOnboarding({
    required Map<String, dynamic> onboardingData,
    String? formattedAddress,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _dioClient.post(
        ApiConstants.usersOnboard,
        data: {
          'onboarding_data': onboardingData,
          'formated_address': formattedAddress,
          'latitude': latitude,
          'longitude': longitude,
          'is_default': true,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<Map<String, dynamic>> getOnboardingStatus() async {
    // Note: The spec doesn't have a dedicated onboarding status endpoint.
    // Onboarding status is typically included in the user profile (/users/me).
    // Returning a default response for now to avoid breaking existing callers.
    return {'is_onboarded': false};
  }
}
