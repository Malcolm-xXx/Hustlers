import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/models/wallet_models.dart';
import 'wallet_provider.dart';

enum WithdrawStep { amount, enterAccount, processing, otp, success }

class WithdrawState {
  final WithdrawStep step;
  final double amount;
  // Account entry
  final String newBankName;
  final String newBankCode;
  final String newAccountNumber;
  final String? verifiedAccountName;
  final bool isVerifying;
  // After submission
  final String? transferCode;
  final bool requiresOtp;
  final String otp;
  // For success display
  final LinkedBankAccount? selectedAccount;
  // UI
  final bool isProcessing;
  final String? error;

  const WithdrawState({
    this.step = WithdrawStep.amount,
    this.amount = 0,
    this.newBankName = '',
    this.newBankCode = '',
    this.newAccountNumber = '',
    this.verifiedAccountName,
    this.isVerifying = false,
    this.transferCode,
    this.requiresOtp = false,
    this.otp = '',
    this.selectedAccount,
    this.isProcessing = false,
    this.error,
  });

  bool get canSubmit =>
      newBankCode.isNotEmpty &&
      newAccountNumber.length == 10 &&
      verifiedAccountName != null;

  bool get isOtpComplete => otp.length == 6;

  int get progressStep => switch (step) {
        WithdrawStep.amount => 1,
        WithdrawStep.enterAccount => 2,
        WithdrawStep.processing || WithdrawStep.otp || WithdrawStep.success => 3,
      };

  WithdrawState copyWith({
    WithdrawStep? step,
    double? amount,
    String? newBankName,
    String? newBankCode,
    String? newAccountNumber,
    String? verifiedAccountName,
    bool clearVerifiedName = false,
    bool? isVerifying,
    String? transferCode,
    bool? requiresOtp,
    String? otp,
    LinkedBankAccount? selectedAccount,
    bool? isProcessing,
    String? error,
    bool clearError = false,
  }) =>
      WithdrawState(
        step: step ?? this.step,
        amount: amount ?? this.amount,
        newBankName: newBankName ?? this.newBankName,
        newBankCode: newBankCode ?? this.newBankCode,
        newAccountNumber: newAccountNumber ?? this.newAccountNumber,
        verifiedAccountName: clearVerifiedName
            ? null
            : (verifiedAccountName ?? this.verifiedAccountName),
        isVerifying: isVerifying ?? this.isVerifying,
        transferCode: transferCode ?? this.transferCode,
        requiresOtp: requiresOtp ?? this.requiresOtp,
        otp: otp ?? this.otp,
        selectedAccount: selectedAccount ?? this.selectedAccount,
        isProcessing: isProcessing ?? this.isProcessing,
        error: clearError ? null : (error ?? this.error),
      );
}

class WithdrawNotifier extends Notifier<WithdrawState> {
  @override
  WithdrawState build() => const WithdrawState();

  void setAmount(double amount) => state = state.copyWith(amount: amount);

  void proceed() => state = state.copyWith(step: WithdrawStep.enterAccount);

  void setBankCode(String name, String code) => state = state.copyWith(
        newBankName: name,
        newBankCode: code,
        clearVerifiedName: true,
      );

  void setAccountNumber(String number) {
    state = state.copyWith(
      newAccountNumber: number,
      clearVerifiedName: true,
      isVerifying: false,
    );
    if (number.length == 10) _verifyAccount(number);
  }

  Future<void> _verifyAccount(String number) async {
    state = state.copyWith(isVerifying: true);
    // Mock verification — replace with real endpoint if API exposes one
    await Future.delayed(const Duration(milliseconds: 1200));
    if (state.newAccountNumber == number) {
      state = state.copyWith(isVerifying: false, verifiedAccountName: 'Account Verified');
    }
  }

  void setOtp(String value) => state = state.copyWith(otp: value);

  Future<void> submitWithdrawal() async {
    if (!state.canSubmit) return;
    state = state.copyWith(step: WithdrawStep.processing, isProcessing: true, clearError: true);

    try {
      final ds = ref.read(walletRemoteDatasourceProvider);

      // Step 1: create transfer recipient
      final recipient = await ds.createTransferRecipient(
        name: state.verifiedAccountName!,
        bankCode: state.newBankCode,
        accountNumber: state.newAccountNumber,
      );

      // Store the account info for the success screen
      final acct = LinkedBankAccount(
        id: recipient.recipientCode,
        bankName: state.newBankName,
        bankCode: state.newBankCode,
        lastFour: state.newAccountNumber.substring(state.newAccountNumber.length - 4),
        accountName: state.verifiedAccountName!,
        recipientCode: recipient.recipientCode,
      );

      // Step 2: submit withdrawal
      final result = await ds.withdraw(
        amount: state.amount.toInt(),
        recipientCode: recipient.recipientCode,
      );

      ref.read(walletProvider.notifier).refresh();

      if (result.requiresOtp && result.transferCode != null) {
        state = state.copyWith(
          isProcessing: false,
          step: WithdrawStep.otp,
          transferCode: result.transferCode,
          requiresOtp: true,
          selectedAccount: acct,
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          step: WithdrawStep.success,
          selectedAccount: acct,
        );
      }
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) {
        state = state.copyWith(isProcessing: false, step: WithdrawStep.enterAccount);
        return;
      }
      state = state.copyWith(
        isProcessing: false,
        step: WithdrawStep.enterAccount,
        error: AppErrorHandler.getUserMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        step: WithdrawStep.enterAccount,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> finalizeWithdrawal() async {
    if (!state.isOtpComplete || state.transferCode == null) return;
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      await ref.read(walletRemoteDatasourceProvider).finalizeWithdrawal(
            transferCode: state.transferCode!,
            otp: state.otp,
          );
      ref.read(walletProvider.notifier).refresh();
      state = state.copyWith(isProcessing: false, step: WithdrawStep.success);
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) {
        state = state.copyWith(isProcessing: false);
        return;
      }
      state = state.copyWith(
        isProcessing: false,
        error: AppErrorHandler.getUserMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> resendOtp() async {
    if (state.transferCode == null) return;
    try {
      await ref.read(walletRemoteDatasourceProvider).resendWithdrawOtp(
            transferCode: state.transferCode!,
          );
    } on ApiException catch (_) {
      // Silent fail — user will see no change
    }
  }

  void back() {
    switch (state.step) {
      case WithdrawStep.enterAccount:
        state = state.copyWith(step: WithdrawStep.amount);
        break;
      default:
        break;
    }
  }

  void reset() => state = const WithdrawState();
}

final withdrawProvider =
    NotifierProvider<WithdrawNotifier, WithdrawState>(WithdrawNotifier.new);
