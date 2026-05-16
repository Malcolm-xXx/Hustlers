import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import 'auth_state_provider.dart';

final googleSignInProvider =
    NotifierProvider<GoogleSignInNotifier, GoogleSignInState>(
      GoogleSignInNotifier.new,
    );

class GoogleSignInState {
  final bool isLoading;
  final String? error;

  const GoogleSignInState({this.isLoading = false, this.error});

  GoogleSignInState copyWith({bool? isLoading, String? error}) {
    return GoogleSignInState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GoogleSignInNotifier extends Notifier<GoogleSignInState> {
  final _googleSignIn = GoogleSignIn();

  @override
  GoogleSignInState build() => const GoogleSignInState();

  Future<void> signIn(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User dismissed the picker — not an error
        state = state.copyWith(isLoading: false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Google sign-in failed: no ID token received.',
        );
        return;
      }

      final tokens = await ref.read(socialLoginUseCaseProvider).call(idToken: idToken);

      await ref.read(authStateProvider.notifier).saveTokens(tokens);
      await ref.read(authStateProvider.notifier).loadCurrentUser();

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        context.goNamed(RouteNames.home);
      }
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false, error: AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }
  }
}
