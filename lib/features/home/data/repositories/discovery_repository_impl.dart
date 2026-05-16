import '../../../product/data/models/product_model.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../datasources/discovery_remote_datasource.dart';
import '../../domain/entities/home_feed_entity.dart';
import '../../domain/entities/seller_entity.dart';
import '../../domain/repositories/i_discovery_repository.dart';
import '../models/seller_model.dart';

class DiscoveryRepositoryImpl implements IDiscoveryRepository {
  final DiscoveryRemoteDatasource _datasource;

  DiscoveryRepositoryImpl(this._datasource);

  @override
  Future<HomeFeedEntity> getHomeFeed() async {
    // Since discovery/home is gone, we fetch items and sellers in parallel
    final results = await Future.wait([
      _datasource.listDiscoveryItems(limit: 10),
      _datasource.listSellers(limit: 5),
    ]);

    final items = results[0] as List<ProductModel>;
    final sellers = results[1] as List<SellerModel>;

    return HomeFeedEntity(
      categories: [], // Categories might need a separate fetch or are static for now
      topSellers: sellers.map((m) => m.toEntity()).toList(),
      featuredProducts: items.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<List<ProductEntity>> search(String query) async {
    final data = await _datasource.search(query);
    final List<dynamic> items = data['data'] ?? [];
    return items.map((e) => ProductModel.fromJson(e as Map<String, dynamic>).toEntity()).toList();
  }

  @override
  Future<List<SellerEntity>> getDiscoverSellers({int limit = 20}) async {
    final models = await _datasource.listSellers(limit: limit);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ProductEntity>> getDiscoveryItems({int limit = 20, String? category}) async {
    final models = await _datasource.listDiscoveryItems(limit: limit, category: category);
    return models.map((m) => m.toEntity()).toList();
  }
}
