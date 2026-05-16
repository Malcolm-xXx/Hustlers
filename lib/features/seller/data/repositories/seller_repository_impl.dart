import '../../domain/repositories/i_seller_repository.dart';
import '../datasources/seller_remote_datasource.dart';
import '../models/seller_analytics_models.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/data/models/product_model.dart';

class SellerRepositoryImpl implements ISellerRepository {
  final SellerRemoteDatasource _datasource;

  SellerRepositoryImpl(this._datasource);

  @override
  Future<SellerInsightModel> getInsights({String range = 'week'}) async {
    return _datasource.getOverview(range: range);
  }

  @override
  Future<List<HotZoneModel>> getHotZones({String range = 'week', int limit = 5}) async {
    return _datasource.getHotZones(range: range, limit: limit);
  }

  @override
  Future<List<TopListingModel>> getTopListings({String range = 'week', int limit = 5}) async {
    return _datasource.getTopListings(range: range, limit: limit);
  }

  @override
  Future<List<ServiceAreaOpportunityModel>> getOpportunities({int limit = 10}) async {
    return _datasource.getOpportunities(limit: limit);
  }

  @override
  Future<List<ProductEntity>> getSellerProducts(String sellerId) async {
    final data = await _datasource.getSellerProducts(sellerId);
    final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
    return results.map((e) => ProductModel.fromJson(e as Map<String, dynamic>).toEntity()).toList();
  }
}
