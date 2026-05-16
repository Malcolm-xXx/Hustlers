import '../../data/models/seller_analytics_models.dart';
import '../../../product/domain/entities/product_entity.dart';

abstract class ISellerRepository {
  Future<SellerInsightModel> getInsights({String range = 'week'});
  Future<List<HotZoneModel>> getHotZones({String range = 'week', int limit = 5});
  Future<List<TopListingModel>> getTopListings({String range = 'week', int limit = 5});
  Future<List<ServiceAreaOpportunityModel>> getOpportunities({int limit = 10});
  Future<List<ProductEntity>> getSellerProducts(String sellerId);
}
