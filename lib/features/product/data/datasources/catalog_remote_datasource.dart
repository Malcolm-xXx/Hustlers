import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/tag_model.dart';

class CatalogRemoteDatasource {
  final DioClient _dioClient;

  CatalogRemoteDatasource(this._dioClient);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dioClient.get(ApiConstants.catalogCategories);
      final data = response.data;
      final List<dynamic> results = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as List<dynamic>
          : data as List<dynamic>;
      return results.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<TagModel>> getTags() async {
    try {
      final response = await _dioClient.get(ApiConstants.catalogTags);
      final data = response.data;
      final List<dynamic> results = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as List<dynamic>
          : data as List<dynamic>;
      return results.map((e) => TagModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<ProductModel>> getProducts({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.catalogProducts,
        queryParameters: queryParameters,
      );
      final data = response.data;
      final List<dynamic> results = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as List<dynamic>
          : data as List<dynamic>;
      return results.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<ProductModel> getProductDetails(String productId) async {
    try {
      final response = await _dioClient.get(ApiConstants.catalogProductDetails(productId));
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
