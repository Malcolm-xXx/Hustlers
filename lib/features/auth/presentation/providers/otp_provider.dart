import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../preferences/presentation/widgets/email_verified_dialog.dart';
import 'auth_state_provider.dart';
import 'sign_up_provider.dart';

final otpProvider =
    NotifierProvider<OtpNotifier, OtpState>(OtpNotifier.new);

class OtpState {
  final String otp;
  final bool isLoading;
  final String? error;
  final int resendCountdown;

  const OtpState({
    this.otp = '',
    this.isLoading = false,
    this.error,
    this.resendCountdown = 0,
  });

  bool get isOtpComplete => otp.length == 6;
  bool get canResend => resendCountdown == 0;

  OtpState copyWith({
    String? otp,
    bool? isLoading,
    String? error,
    int? resendCountdown,
  }) {
    return OtpState(
      otp: otp ?? this.otp,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      resendCountdown: resendCountdown ?? this.resendCountdown,
    );
  }
}

class OtpNotifier extends Notifier<OtpState> {
  Timer? _resendTimer;

  @override
  OtpState build() => const OtpState();

  void setOtp(String value) => state = state.copyWith(otp: value);

  Future<void> verifyOtp(BuildContext context) async {
    if (!state.isOtpComplete) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final email = ref.read(signUpProvider).email;
      final tokens = await ref.read(verifyOtpUseCaseProvider).call(
            email: email,
            otp: state.otp,
          );

      await ref.read(authStateProvider.notifier).saveTokens(tokens);
      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        EmailVerifiedDialog.show(
          context,
          onSetPreferences: () {
            Navigator.of(context).pop();
            context.goNamed(RouteNames.primaryGoal);
          },
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false);
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(error: AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }
  }

  void navigateToRoleSelection(BuildContext context) {
    if (context.mounted) {
      EmailVerifiedDialog.show(
        context,
        onSetPreferences: () {
          Navigator.of(context).pop();
          context.goNamed(RouteNames.primaryGoal);
        },
      );
    }
  }

  Future<void> resendOtp() async {
    if (!state.canResend) return;

    try {
      final email = ref.read(signUpProvider).email;
      await ref.read(resendOtpUseCaseProvider).call(email);
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
}
