import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import 'auth_state_provider.dart';

final signUpProvider =
    NotifierProvider<SignUpNotifier, SignUpState>(SignUpNotifier.new);

class SignUpState {
  final String name;
  final String phone;
  final String email;
  final String password;
  final String? selectedRole;
  final String nin;
  final bool isLoading;
  final String? error;
  final bool obscurePassword;

  const SignUpState({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.selectedRole,
    this.nin = '',
    this.isLoading = false,
    this.error,
    this.obscurePassword = true,
  });

  String? get nameError {
    if (name.isEmpty) return null;
    if (name.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? get phoneError {
    if (phone.isEmpty) return null;
    if (phone.length < 8) return 'Enter a valid phone number';
    if (!RegExp(r'^[0-9+]+$').hasMatch(phone)) return 'Phone number can only contain digits and +';
    return null;
  }

  String? get emailError {
    if (email.isEmpty) return null;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? get passwordError {
    if (password.isEmpty) return null;
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  bool get isFormValid =>
      name.isNotEmpty && nameError == null &&
      phone.isNotEmpty && phoneError == null &&
      email.isNotEmpty && emailError == null &&
      password.isNotEmpty && passwordError == null;

  bool get isRoleSelected => selectedRole != null;
  bool get isNinValid => nin.isNotEmpty;

  SignUpState copyWith({
    String? name,
    String? phone,
    String? email,
    String? password,
    String? selectedRole,
    String? nin,
    bool? isLoading,
    String? error,
    bool? obscurePassword,
  }) {
    return SignUpState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      selectedRole: selectedRole ?? this.selectedRole,
      nin: nin ?? this.nin,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

class SignUpNotifier extends Notifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  void setName(String value) => state = state.copyWith(name: value);
  void setPhone(String value) => state = state.copyWith(phone: value);
  void setEmail(String value) => state = state.copyWith(email: value);
  void setPassword(String value) => state = state.copyWith(password: value);
  void setNin(String value) => state = state.copyWith(nin: value);

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void selectRole(String role) {
    state = state.copyWith(selectedRole: role);
  }

  Future<void> submitSignUp(BuildContext context) async {
    if (!state.isFormValid) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      String formattedPhone = state.phone.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+234${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }

      await ref.read(registerUseCaseProvider).call(
            fullName: state.name.trim(),
            phoneNumber: formattedPhone,
            email: state.email.trim(),
            password: state.password,
            confirmPassword: state.password,
          );

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        context.pushNamed(RouteNames.otpVerification);
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

  void navigateToRoleSelection(BuildContext context) {
    if (context.mounted) context.pushNamed(RouteNames.roleSelection);
  }

  void navigateToIdVerification(BuildContext context) {
    if (context.mounted) context.pushNamed(RouteNames.idVerification);
  }

  void navigateToSignUp(BuildContext context) {
    if (context.mounted) context.pushNamed(RouteNames.signUp);
  }

  void navigateToFingerprint(BuildContext context) {
    if (context.mounted) context.pushNamed(RouteNames.fingerprintVerification);
  }

  void navigateToFaceId(BuildContext context) {
    if (context.mounted) context.pushNamed(RouteNames.faceIdVerification);
  }

  void navigateToFaceCapture(BuildContext context) {
    if (context.mounted) context.pushNamed(RouteNames.faceCapture);
  }

  void navigateToHome(BuildContext context) {
    if (context.mounted) context.goNamed(RouteNames.home);
  }
}
