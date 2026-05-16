import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/dio_provider.dart';
import '../models/wallet_models.dart';

final walletRemoteDatasourceProvider = Provider<WalletRemoteDatasource>(
  (ref) => WalletRemoteDatasource(ref.watch(dioClientProvider)),
);

class WalletRemoteDatasource {
  final DioClient _client;
  WalletRemoteDatasource(this._client);

  Future<int> getBalance() async {
    try {
      final res = await _client.get(ApiConstants.wallet);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data['balance'] as int;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<WalletAnalyticsModel> getAnalytics() async {
    try {
      final res = await _client.get(ApiConstants.walletAnalytics);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return WalletAnalyticsModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<WalletTransactionApiModel>> getTransactions({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final res = await _client.get(
        ApiConstants.walletTransactions,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final items = body['data'] as List<dynamic>;
      return items
          .map((e) => WalletTransactionApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<WalletTopupResponseModel> topup({
    required int amount,
    String? cardId,
  }) async {
    try {
      final res = await _client.post(
        ApiConstants.walletTopup,
        data: {
          'amount': amount,
          if (cardId != null) 'card_id': cardId,
          'callback_url': ApiConstants.paystackCallbackUrl,
        },
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return WalletTopupResponseModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<TransferRecipientModel> createTransferRecipient({
    required String name,
    required String bankCode,
    required String accountNumber,
  }) async {
    try {
      final res = await _client.post(
        ApiConstants.walletTransferRecipient,
        data: {
          'name': name,
          'bank_code': bankCode,
          'account_number': accountNumber,
        },
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return TransferRecipientModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<WalletWithdrawResponseModel> withdraw({
    required int amount,
    required String recipientCode,
    String? description,
  }) async {
    try {
      final res = await _client.post(
        ApiConstants.walletWithdraw,
        data: {
          'amount': amount,
          'recipient_code': recipientCode,
          if (description != null) 'description': description,
        },
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return WalletWithdrawResponseModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> finalizeWithdrawal({
    required String transferCode,
    required String otp,
  }) async {
    try {
      await _client.post(
        ApiConstants.walletWithdrawFinalize,
        data: {'transfer_code': transferCode, 'otp': otp},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> resendWithdrawOtp({required String transferCode}) async {
    try {
      await _client.post(
        ApiConstants.walletWithdrawResendOtp,
        data: {'transfer_code': transferCode},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
