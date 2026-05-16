import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import '../widgets/password_updated_dialog.dart';
import 'auth_state_provider.dart';

final forgotPasswordProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
      ForgotPasswordNotifier.new,
    );

class ForgotPasswordState {
  final String email;
  final String otp;
  final String resetToken; // returned from verify-otp step
  final String newPassword;
  final String confirmPassword;
  final bool isPasswordVisible;
  final bool isConfirmVisible;
  final bool isLoading;
  final String? error;
  final int resendCountdown;

  const ForgotPasswordState({
    this.email = '',
    this.otp = '',
    this.resetToken = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.isPasswordVisible = false,
    this.isConfirmVisible = false,
    this.isLoading = false,
    this.error,
    this.resendCountdown = 0,
  });

  bool get canResend => resendCountdown == 0;

  bool get canSendCode => email.trim().isNotEmpty;

  bool get isOtpComplete => otp.length == 6;

  bool get canResetPassword =>
      resetToken.isNotEmpty &&
      newPassword.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      newPassword == confirmPassword;

  ForgotPasswordState copyWith({
    String? email,
    String? otp,
    String? resetToken,
    String? newPassword,
    String? confirmPassword,
    bool? isPasswordVisible,
    bool? isConfirmVisible,
    bool? isLoading,
    String? error,
    int? resendCountdown,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      otp: otp ?? this.otp,
      resetToken: resetToken ?? this.resetToken,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmVisible: isConfirmVisible ?? this.isConfirmVisible,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      resendCountdown: resendCountdown ?? this.resendCountdown,
    );
  }
}

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  Timer? _resendTimer;

  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  void setEmail(String value) => state = state.copyWith(email: value);
  void setOtp(String value) => state = state.copyWith(otp: value);
  void setNewPassword(String value) => state = state.copyWith(newPassword: value);
  void setConfirmPassword(String value) =>
      state = state.copyWith(confirmPassword: value);
  void togglePasswordVisibility() =>
      state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  void toggleConfirmVisibility() =>
      state = state.copyWith(isConfirmVisible: !state.isConfirmVisible);

  Future<void> resendOtp() async {
    if (!state.canResend) return;

    try {
      await ref.read(resendPasswordOtpUseCaseProvider).call(state.email.trim());
      _startResendCountdown();
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(error: AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(error: 'Something went wrong. Please try again.');
    }
  }

  void _startResendCountdown() {
    state = state.copyWith(resendCountdown: 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown <= 1) {
        timer.cancel();
        state = state.copyWith(resendCountdown: 0);
      } else {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      }
    });
  }

  /// Step 1 — send OTP to email.
  Future<void> sendCode(BuildContext context) async {
    if (!state.canSendCode) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(forgotPasswordUseCaseProvider).call(state.email.trim());
      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        context.goNamed(RouteNames.forgotPasswordOtp);
      }
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false, error: AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }
  }

  /// Step 2 — verify OTP and store the returned verification token.
  Future<void> verifyOtp(BuildContext context) async {
    if (!state.isOtpComplete) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await ref
          .read(verifyPasswordResetOtpUseCaseProvider)
          .call(email: state.email, otp: state.otp);

      state = state.copyWith(isLoading: false, resetToken: token);

      if (context.mounted) {
        context.goNamed(RouteNames.resetPassword);
      }
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false, error: AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }
  }

  /// Step 3 — set new password using the verification token.
  Future<void> resetPassword(BuildContext context) async {
    if (!state.canResetPassword) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(resetPasswordUseCaseProvider).call(
            resetToken: state.resetToken,
            newPassword: state.newPassword,
            confirmPassword: state.confirmPassword,
          );
      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        PasswordUpdatedDialog.show(
          context,
          onSignIn: () {
            Navigator.of(context).pop();
            context.goNamed(RouteNames.signIn);
          },
        );
      }
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false, error: AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }
  }
}
