class AppConstants {
  AppConstants._();

  static const String appName = 'Hustlers';

  /// Flip to false once the backend is live and stable.
  static const bool useMockData = false;


  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';

  static const Duration splashDuration = Duration(seconds: 2);
}
