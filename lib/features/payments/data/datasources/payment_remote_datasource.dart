import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/dio_provider.dart';
import '../models/payment_models.dart';

final paymentRemoteDatasourceProvider = Provider<PaymentRemoteDatasource>(
  (ref) => PaymentRemoteDatasource(ref.watch(dioClientProvider)),
);

class PaymentRemoteDatasource {
  final DioClient _client;
  PaymentRemoteDatasource(this._client);

  Future<List<SavedCardModel>> getSavedCards() async {
    try {
      final res = await _client.get(ApiConstants.paymentCards);
      final body = res.data as Map<String, dynamic>;
      final items = (body['data'] as List<dynamic>?) ?? [];
      return items
          .map((e) => SavedCardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<SavedCardModel> addCard(String authorizationCode) async {
    try {
      final res = await _client.post(
        ApiConstants.paymentCards,
        data: {'authorization_code': authorizationCode},
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return SavedCardModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _client.delete(ApiConstants.paymentCardDetails(cardId));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> setDefaultCard(String cardId) async {
    try {
      await _client.post(
        ApiConstants.paymentCardDefault(cardId),
        data: {'is_default': true},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<PaymentInitResponseModel> initializePayment({
    required String orderId,
    required PaymentMethod method,
    String? savedCardId,
  }) async {
    try {
      final res = await _client.post(
        ApiConstants.paymentsInitialize,
        data: {
          'order_id': orderId,
          'method': method.apiValue,
          if (savedCardId != null) 'saved_card_id': savedCardId,
          'callback_url': ApiConstants.paystackCallbackUrl,
        },
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return PaymentInitResponseModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<PaymentVerifyResponseModel> verifyPayment(String reference) async {
    try {
      final res = await _client.get(ApiConstants.paymentsVerifyRef(reference));
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return PaymentVerifyResponseModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
