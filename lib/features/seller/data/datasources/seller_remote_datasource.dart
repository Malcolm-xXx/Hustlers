import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';
import '../models/seller_analytics_models.dart';

class SellerRemoteDatasource {
  final DioClient _dioClient;

  SellerRemoteDatasource(this._dioClient);

  Future<SellerInsightModel> getOverview({String range = 'week'}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.sellerAnalyticsOverview,
        queryParameters: {'range': range},
      );
      return SellerInsightModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<HotZoneModel>> getHotZones({String range = 'week', int limit = 5}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.sellerAnalyticsHotZones,
        queryParameters: {'range': range, 'limit': limit},
      );
      final data = response.data;
      final List<dynamic> results = data is Map<String, dynamic> && data.containsKey('results')
          ? data['results'] as List<dynamic>
          : data as List<dynamic>;
      return results.map((e) => HotZoneModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<TopListingModel>> getTopListings({String range = 'week', int limit = 5}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.sellerAnalyticsTopListings,
        queryParameters: {'range': range, 'limit': limit},
      );
      final data = response.data;
      final List<dynamic> results = data is Map<String, dynamic> && data.containsKey('results')
          ? data['results'] as List<dynamic>
          : data as List<dynamic>;
      return results.map((e) => TopListingModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<List<ServiceAreaOpportunityModel>> getOpportunities({int limit = 10}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.sellerAnalyticsOpportunities,
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      final List<dynamic> results = data is Map<String, dynamic> && data.containsKey('results')
          ? data['results'] as List<dynamic>
          : data as List<dynamic>;
      return results.map((e) => ServiceAreaOpportunityModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<Map<String, dynamic>> getSellerProducts(String sellerId) async {
    try {
      final response = await _dioClient.get(ApiConstants.sellerProducts(sellerId));
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
