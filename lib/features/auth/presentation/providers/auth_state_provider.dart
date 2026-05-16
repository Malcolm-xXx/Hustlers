import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/resend_otp_usecase.dart';
import '../../domain/usecases/resend_password_otp_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/verify_password_reset_otp_usecase.dart';

// ───── Use Case Providers ─────

final registerUseCaseProvider =
    Provider((ref) => RegisterUseCase(ref.watch(authRepositoryProvider)));

final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));

final socialLoginUseCaseProvider =
    Provider((ref) => SocialLoginUseCase(ref.watch(authRepositoryProvider)));

final verifyOtpUseCaseProvider =
    Provider((ref) => VerifyOtpUseCase(ref.watch(authRepositoryProvider)));

final resendOtpUseCaseProvider =
    Provider((ref) => ResendOtpUseCase(ref.watch(authRepositoryProvider)));

final resendPasswordOtpUseCaseProvider =
    Provider((ref) => ResendPasswordOtpUseCase(ref.watch(authRepositoryProvider)));

final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));

final getMeUseCaseProvider =
    Provider((ref) => GetMeUseCase(ref.watch(authRepositoryProvider)));

final forgotPasswordUseCaseProvider =
    Provider((ref) => ForgotPasswordUseCase(ref.watch(authRepositoryProvider)));

final resetPasswordUseCaseProvider =
    Provider((ref) => ResetPasswordUseCase(ref.watch(authRepositoryProvider)));

final verifyPasswordResetOtpUseCaseProvider = Provider(
    (ref) => VerifyPasswordResetOtpUseCase(ref.watch(authRepositoryProvider)));

final refreshTokenUseCaseProvider =
    Provider((ref) => RefreshTokenUseCase(ref.watch(authRepositoryProvider)));

// ───── Global Auth State ─────

final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool sessionExpired;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.sessionExpired = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserEntity? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool? sessionExpired,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> loadCurrentUser() async {
    final storage = ref.read(localStorageServiceProvider);
    if (!storage.isLoggedIn) return;

    state = state.copyWith(isLoading: true);
    try {
      final user = await ref.read(getMeUseCaseProvider)();
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setUser(UserEntity user) {
    state = state.copyWith(user: user);
  }

  Future<void> saveTokens(AuthTokensEntity tokens) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setAccessToken(tokens.accessToken);
    await storage.setRefreshToken(tokens.refreshToken);
  }

  Future<void> logout() async {
    final storage = ref.read(localStorageServiceProvider);
    final refreshToken = storage.refreshToken;
    if (refreshToken != null) {
      try {
        await ref
            .read(logoutUseCaseProvider)
            .call(refreshToken: refreshToken);
      } catch (_) {
        // Best-effort — clear local state regardless
      }
    }
    await storage.clearAuth();
    state = state.copyWith(clearUser: true);
  }

  /// Called by DioClient interceptor when a 401 is received on any request.
  Future<void> expireSession() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.clearAuth();
    state = state.copyWith(clearUser: true, sessionExpired: true);
  }

  void clearSessionExpired() {
    state = state.copyWith(sessionExpired: false);
  }
}
