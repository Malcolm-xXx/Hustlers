import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/dio_provider.dart';
import '../models/stash_models.dart';

final stashRemoteDatasourceProvider = Provider<StashRemoteDatasource>(
  (ref) => StashRemoteDatasource(ref.watch(dioClientProvider)),
);

class StashRemoteDatasource {
  final DioClient _client;
  StashRemoteDatasource(this._client);

  Future<StashApiModel> getStash() async {
    try {
      final res = await _client.get(ApiConstants.stash);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return StashApiModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<StashApiModel> addItem({
    required String productId,
    required int quantity,
  }) async {
    try {
      final res = await _client.post(
        ApiConstants.stashItems,
        data: {'product_id': productId, 'quantity': quantity},
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return StashApiModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<StashApiModel> updateItem(String itemId, int quantity) async {
    try {
      final res = await _client.patch(
        ApiConstants.stashItemDetail(itemId),
        data: {'quantity': quantity},
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return StashApiModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<StashApiModel> deleteItem(String itemId) async {
    try {
      final res = await _client.delete(ApiConstants.stashItemDetail(itemId));
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return StashApiModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> clearStash() async {
    try {
      await _client.delete(ApiConstants.stash);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<StashApiModel> updateStash({
    String? deliveryLocationId,
    String? specialInstructions,
  }) async {
    try {
      final res = await _client.patch(
        ApiConstants.stash,
        data: {
          if (deliveryLocationId != null) 'delivery_location_id': deliveryLocationId,
          if (specialInstructions != null) 'special_instructions': specialInstructions,
        },
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return StashApiModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<StashApiModel>> getSavedStashes() async {
    try {
      final res = await _client.get(ApiConstants.stashSaved);
      final body = res.data as Map<String, dynamic>;
      final items = (body['data'] as List<dynamic>?) ?? [];
      return items
          .map((e) => StashApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> saveForLater() async {
    try {
      await _client.post(ApiConstants.stashSaveForLater);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
