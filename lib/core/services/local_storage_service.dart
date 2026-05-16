import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'shared_prefs_provider.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);


  bool get hasCompletedOnboarding =>
      _prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete() =>
      _prefs.setBool(AppConstants.onboardingCompleteKey, true);

  // ───── Auth Tokens ─────

  String? get accessToken => _prefs.getString(AppConstants.accessTokenKey);

  Future<void> setAccessToken(String token) =>
      _prefs.setString(AppConstants.accessTokenKey, token);

  Future<void> removeAccessToken() =>
      _prefs.remove(AppConstants.accessTokenKey);

  String? get refreshToken => _prefs.getString(AppConstants.refreshTokenKey);

  Future<void> setRefreshToken(String token) =>
      _prefs.setString(AppConstants.refreshTokenKey, token);

  Future<void> removeRefreshToken() =>
      _prefs.remove(AppConstants.refreshTokenKey);


  String? get userId => _prefs.getString(AppConstants.userIdKey);

  Future<void> setUserId(String id) =>
      _prefs.setString(AppConstants.userIdKey, id);

  Future<void> removeUserId() => _prefs.remove(AppConstants.userIdKey);


  // ───── User Role ─────

  String? get userRole => _prefs.getString(AppConstants.userRoleKey);

  Future<void> setUserRole(String role) =>
      _prefs.setString(AppConstants.userRoleKey, role);

  Future<void> removeUserRole() => _prefs.remove(AppConstants.userRoleKey);

  bool get isLoggedIn => accessToken != null;

  Future<void> clearAuth() async {
    await removeAccessToken();
    await removeRefreshToken();
    await removeUserId();
    await removeUserRole();
  }

  Future<void> clearAll() => _prefs.clear();
}
