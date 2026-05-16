abstract class IOnboardingRepository {
  Future<void> completeOnboarding({
    required Map<String, dynamic> onboardingData,
    String? formattedAddress,
    double? latitude,
    double? longitude,
  });
  
  Future<Map<String, dynamic>> getOnboardingStatus();
}
