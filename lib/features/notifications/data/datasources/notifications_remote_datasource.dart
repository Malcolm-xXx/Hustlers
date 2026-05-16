import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/dio_provider.dart';
import '../models/notification_model.dart';

final notificationsRemoteDatasourceProvider =
    Provider<NotificationsRemoteDatasource>(
  (ref) => NotificationsRemoteDatasource(ref.watch(dioClientProvider)),
);

class NotificationsRemoteDatasource {
  final DioClient _client;
  NotificationsRemoteDatasource(this._client);

  Future<List<NotificationApiModel>> getNotifications({String? cursor}) async {
    try {
      final res = await _client.get(
        ApiConstants.notifications,
        queryParameters: {if (cursor != null) 'cursor': cursor},
      );
      final body = res.data as Map<String, dynamic>;
      final items = (body['data'] as List<dynamic>?) ?? [];
      return items
          .map((e) =>
              NotificationApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _client.patch(
        ApiConstants.notificationRead(notificationId),
        data: {'is_read': true},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.patch(ApiConstants.notificationsReadAll);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
