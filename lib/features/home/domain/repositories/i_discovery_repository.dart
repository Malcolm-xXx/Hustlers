import '../../../product/domain/entities/product_entity.dart';
import '../entities/home_feed_entity.dart';
import '../entities/seller_entity.dart';

abstract class IDiscoveryRepository {
  Future<HomeFeedEntity> getHomeFeed();
  Future<List<ProductEntity>> search(String query);
  Future<List<SellerEntity>> getDiscoverSellers({int limit = 20});
  Future<List<ProductEntity>> getDiscoveryItems({int limit = 20, String? category});
}
