import '../datasources/onboarding_remote_datasource.dart';
import '../../domain/repositories/i_onboarding_repository.dart';

class OnboardingRepositoryImpl implements IOnboardingRepository {
  final OnboardingRemoteDatasource _datasource;

  OnboardingRepositoryImpl(this._datasource);

  @override
  Future<void> completeOnboarding({
    required Map<String, dynamic> onboardingData,
    String? formattedAddress,
    double? latitude,
    double? longitude,
  }) async {
    await _datasource.completeOnboarding(
      onboardingData: onboardingData,
      formattedAddress: formattedAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<Map<String, dynamic>> getOnboardingStatus() async {
    return await _datasource.getOnboardingStatus();
  }
}
