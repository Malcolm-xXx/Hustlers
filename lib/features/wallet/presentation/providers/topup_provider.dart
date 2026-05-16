import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import 'wallet_provider.dart';

enum TopUpStep { amount, processing, success }

class TopUpState {
  final TopUpStep step;
  final double amount;
  final bool isProcessing;
  final double newBalance;
  final String? error;

  const TopUpState({
    this.step = TopUpStep.amount,
    this.amount = 0,
    this.isProcessing = false,
    this.newBalance = 0,
    this.error,
  });

  TopUpState copyWith({
    TopUpStep? step,
    double? amount,
    bool? isProcessing,
    double? newBalance,
    String? error,
    bool clearError = false,
  }) =>
      TopUpState(
        step: step ?? this.step,
        amount: amount ?? this.amount,
        isProcessing: isProcessing ?? this.isProcessing,
        newBalance: newBalance ?? this.newBalance,
        error: clearError ? null : (error ?? this.error),
      );
}

class TopUpNotifier extends Notifier<TopUpState> {
  @override
  TopUpState build() => const TopUpState();

  void setAmount(double amount) => state = state.copyWith(amount: amount);

  /// Returns the Paystack authorization_url if a redirect is needed, null otherwise.
  Future<String?> initiateTopup() async {
    state = state.copyWith(step: TopUpStep.processing, isProcessing: true, clearError: true);
    try {
      final response = await ref.read(walletRemoteDatasourceProvider).topup(
            amount: state.amount.toInt(),
          );
      state = state.copyWith(isProcessing: false);

      if (response.authorizationUrl != null) {
        return response.authorizationUrl;
      }

      // Direct charge succeeded
      ref.read(walletProvider.notifier).refresh();
      state = state.copyWith(
        step: TopUpStep.success,
        newBalance: ref.read(walletProvider).balance + state.amount,
      );
      return null;
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) {
        state = state.copyWith(isProcessing: false, step: TopUpStep.amount);
        return null;
      }
      state = state.copyWith(
        isProcessing: false,
        step: TopUpStep.amount,
        error: AppErrorHandler.getUserMessage(e),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isProcessing: false,
        step: TopUpStep.amount,
        error: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  void handlePaystackSuccess() {
    ref.read(walletProvider.notifier).refresh();
    state = state.copyWith(step: TopUpStep.success);
  }

  void reset() => state = const TopUpState();
}

final topUpProvider =
    NotifierProvider<TopUpNotifier, TopUpState>(TopUpNotifier.new);
