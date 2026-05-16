import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../../../product/data/models/product_model.dart';
import '../models/seller_model.dart';

class DiscoveryRemoteDatasource {
  final DioClient _dioClient;

  DiscoveryRemoteDatasource(this._dioClient);

  Future<List<ProductModel>> listDiscoveryItems({
    String? cursor,
    int limit = 20,
    String? search,
    String? category,
    String? filter,
    double? distance,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.discoveryItems,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
          if (search != null) 'search': search,
          if (category != null) 'category': category,
          if (filter != null) 'filter': filter,
          if (distance != null) 'distance': distance,
        },
      );
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : data as List<dynamic>;
      return items.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<SellerModel>> listSellers({
    String? cursor,
    int limit = 20,
    String? search,
    String? filter,
    double? distance,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.discoverySellers,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
          if (search != null) 'search': search,
          if (filter != null) 'filter': filter,
          if (distance != null) 'distance': distance,
        },
      );
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : data as List<dynamic>;
      return items.map((e) => SellerModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.discoverySearch,
        queryParameters: {'q': query},
      );
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
