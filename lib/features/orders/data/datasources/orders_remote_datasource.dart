import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/dio_provider.dart';
import '../models/order_model.dart';

final ordersRemoteDatasourceProvider = Provider<OrdersRemoteDatasource>(
  (ref) => OrdersRemoteDatasource(ref.watch(dioClientProvider)),
);

class OrdersRemoteDatasource {
  final DioClient _client;
  OrdersRemoteDatasource(this._client);

  Future<List<OrderModel>> getActiveOrders() async {
    try {
      final res = await _client.get(ApiConstants.orders);
      final body = res.data as Map<String, dynamic>;
      final items = (body['data'] as List<dynamic>?) ?? [];
      return items
          .map((e) => OrderModel.fromSummaryJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<OrderModel> getOrderDetail(String orderId) async {
    try {
      final res = await _client.get(ApiConstants.orderDetail(orderId));
      final data =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return OrderModel.fromDetailJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<OrderModel>> getOrderHistory({String? cursor, int limit = 20}) async {
    try {
      final res = await _client.get(
        ApiConstants.ordersHistory,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final items = (body['data'] as List<dynamic>?) ?? [];
      return items
          .map((e) => _historyToOrderModel(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _client.post(ApiConstants.orderCancel(orderId));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> cancelOrderItem(String orderId, String itemId,
      {String? reason}) async {
    try {
      await _client.post(
        ApiConstants.orderItemCancel(orderId, itemId),
        data: {if (reason != null) 'reason': reason},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> rateOrder(
    String orderId, {
    required int rating,
    List<String>? feedbackTags,
    String? review,
  }) async {
    try {
      await _client.post(
        ApiConstants.orderRate(orderId),
        data: {
          'rating': rating,
          if (feedbackTags != null && feedbackTags.isNotEmpty)
            'feedback_tags': feedbackTags,
          if (review != null) 'review': review,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  /// Maps `BuyerOrderHistoryResponse` to `OrderModel`.
  OrderModel _historyToOrderModel(Map<String, dynamic> json) {
    final items = ((json['items'] as List<dynamic>?) ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return OrderItemModel(
            id: '',
            name: m['name'] as String? ?? '',
            quantity: '${m['quantity']} ${m['unit_label']}',
            price: 0,
            isCompleted: true,
          );
        })
        .toList();

    return OrderModel(
      id: '',
      orderNumber: '#${json['order_number']}',
      status: OrderStatus.fromApiValue(json['status'] as String? ?? 'done'),
      hustlerName: '',
      hustlerRole: 'Hustler',
      hustlerImageUrl: '',
      location: '',
      deliveryAddress: '',
      eta: '',
      items: items,
      total: (json['total'] as int? ?? 0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
