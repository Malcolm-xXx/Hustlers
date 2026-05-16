import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import 'auth_state_provider.dart';

final signInProvider =
    NotifierProvider<SignInNotifier, SignInState>(SignInNotifier.new);

class SignInState {
  final String email;
  final String password;
  final bool isLoading;
  final String? error;
  final bool obscurePassword;

  const SignInState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.error,
    this.obscurePassword = true,
  });

  bool get isFormValid => email.isNotEmpty && password.isNotEmpty;

  SignInState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? error,
    bool? obscurePassword,
  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

class SignInNotifier extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  void setEmail(String value) => state = state.copyWith(email: value);
  void setPassword(String value) => state = state.copyWith(password: value);

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> submitSignIn(BuildContext context) async {
    if (!state.isFormValid) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final tokens = await ref.read(loginUseCaseProvider).call(
            email: state.email,
            password: state.password,
          );
      await ref.read(authStateProvider.notifier).saveTokens(tokens);
      await ref.read(authStateProvider.notifier).loadCurrentUser();

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        context.goNamed(RouteNames.home);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }
  }

  void navigateToOtp(BuildContext context) {
    if (context.mounted) context.pushNamed(RouteNames.otpVerification);
  }

  void navigateToSignUp(BuildContext context) {
    if (context.mounted) context.pushNamed(RouteNames.signUp);
  }

  void navigateToHome(BuildContext context) {
    if (context.mounted) context.goNamed(RouteNames.home);
  }
}
