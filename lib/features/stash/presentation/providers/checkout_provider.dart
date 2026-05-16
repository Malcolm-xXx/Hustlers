import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/services/dio_provider.dart';
import '../../../payments/data/datasources/payment_remote_datasource.dart';
import '../../../payments/data/models/payment_models.dart';
import '../../data/models/stash_models.dart';

final checkoutProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

enum CheckoutStep { payment, review }

class CheckoutState {
  final CheckoutStep step;
  final PaymentMethod? selectedMethod;
  final List<SavedCard> savedCards;
  final String? selectedCardId;
  final bool isProcessing;
  final bool isSuccess;
  final String? error;

  const CheckoutState({
    this.step = CheckoutStep.payment,
    this.selectedMethod,
    this.savedCards = const [],
    this.selectedCardId,
    this.isProcessing = false,
    this.isSuccess = false,
    this.error,
  });

  SavedCard? get selectedCard =>
      savedCards.where((c) => c.id == selectedCardId).firstOrNull;

  bool get canProceed =>
      selectedMethod != null &&
      (selectedMethod != PaymentMethod.card ||
          selectedCardId != null ||
          savedCards.isEmpty);

  CheckoutState copyWith({
    CheckoutStep? step,
    PaymentMethod? selectedMethod,
    List<SavedCard>? savedCards,
    String? selectedCardId,
    bool? isProcessing,
    bool? isSuccess,
    String? error,
    bool clearMethod = false,
    bool clearCard = false,
    bool clearError = false,
  }) {
    return CheckoutState(
      step: step ?? this.step,
      selectedMethod:
          clearMethod ? null : (selectedMethod ?? this.selectedMethod),
      savedCards: savedCards ?? this.savedCards,
      selectedCardId: clearCard ? null : (selectedCardId ?? this.selectedCardId),
      isProcessing: isProcessing ?? this.isProcessing,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    Future.microtask(_loadSavedCards);
    return const CheckoutState();
  }

  Future<void> _loadSavedCards() async {
    try {
      final cards = await ref.read(paymentRemoteDatasourceProvider).getSavedCards();
      final savedCards = cards.map(SavedCard.fromSavedCardModel).toList();
      final defaultCardId =
          savedCards.where((c) => c.isDefault).firstOrNull?.id;
      state = state.copyWith(
        savedCards: savedCards,
        selectedCardId: defaultCardId,
      );
    } on ApiException catch (e) {
      if (!AppErrorHandler.isUnauthorized(e)) {
        // Non-fatal — show empty card list
      }
    } catch (_) {
      // Non-fatal
    }
  }

  void selectMethod(PaymentMethod method) =>
      state = state.copyWith(selectedMethod: method);

  void selectCard(String cardId) =>
      state = state.copyWith(selectedCardId: cardId);

  void proceedToReview() {
    if (state.canProceed) {
      state = state.copyWith(step: CheckoutStep.review);
    }
  }

  /// Returns the Paystack authorization_url if a redirect is needed, null otherwise.
  Future<String?> pay() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final client = ref.read(dioClientProvider);

      // Step 1: Convert stash to orders
      final checkoutRes = await client.post(
        '/api/v1/stash/checkout',
      );
      final checkoutBody = checkoutRes.data as Map<String, dynamic>;
      final orders = (checkoutBody['data'] as List<dynamic>?) ?? [];
      if (orders.isEmpty) {
        state = state.copyWith(isProcessing: false, error: 'No items to checkout.');
        return null;
      }

      final firstOrder = orders.first as Map<String, dynamic>;
      final orderId = firstOrder['order_id'] as String? ?? firstOrder['id'] as String;

      // Step 2: Initialize payment
      final payInit = await ref.read(paymentRemoteDatasourceProvider).initializePayment(
            orderId: orderId,
            method: state.selectedMethod ?? PaymentMethod.wallet,
            savedCardId: state.selectedMethod == PaymentMethod.card
                ? state.selectedCardId
                : null,
          );

      state = state.copyWith(isProcessing: false, isSuccess: true);
      return payInit.authorizationUrl;
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) {
        state = state.copyWith(isProcessing: false);
        return null;
      }
      state = state.copyWith(
        isProcessing: false,
        error: AppErrorHandler.getUserMessage(e),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  void reset() => state = const CheckoutState();
}
