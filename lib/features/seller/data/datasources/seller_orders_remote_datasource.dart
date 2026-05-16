import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/dio_provider.dart';
import '../models/seller_order_model.dart';

final sellerOrdersRemoteDatasourceProvider =
    Provider<SellerOrdersRemoteDatasource>(
  (ref) => SellerOrdersRemoteDatasource(ref.watch(dioClientProvider)),
);

class SellerOrdersRemoteDatasource {
  final DioClient _client;
  SellerOrdersRemoteDatasource(this._client);

  Future<List<SellerOrderModel>> getActiveOrders({String? cursor}) async {
    try {
      final res = await _client.get(
        ApiConstants.sellerActiveOrders,
        queryParameters: {if (cursor != null) 'cursor': cursor},
      );
      final body = res.data as Map<String, dynamic>;
      final items = (body['data'] as List<dynamic>?) ?? [];
      return items
          .map((e) =>
              SellerOrderModel.fromSummaryJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<SellerOrderModel> getOrderDetail(String orderId) async {
    try {
      final res = await _client.get(ApiConstants.sellerOrderDetail(orderId));
      final data =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      // Inject id since SellerOrderDetailResponse doesn't include it
      return SellerOrderModel.fromDetailJson({...data, 'id': orderId});
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> startShopping(String orderId) async {
    try {
      await _client.post(ApiConstants.orderStartShopping(orderId));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> markOnTheWay(String orderId) async {
    try {
      await _client.post(ApiConstants.orderOnTheWay(orderId));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> markDelivered(String orderId) async {
    try {
      await _client.post(ApiConstants.orderDeliver(orderId));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> markItemGotten(String orderId, String itemId) async {
    try {
      await _client.post(ApiConstants.orderItemMarkGotten(orderId, itemId));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
