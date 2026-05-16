import '../datasources/catalog_remote_datasource.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/tag_entity.dart';
import '../../domain/repositories/i_catalog_repository.dart';

class CatalogRepositoryImpl implements ICatalogRepository {
  final CatalogRemoteDatasource _datasource;

  CatalogRepositoryImpl(this._datasource);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final models = await _datasource.getCategories();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<TagEntity>> getTags() async {
    final models = await _datasource.getTags();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ProductEntity>> getProducts({Map<String, dynamic>? filters}) async {
    final models = await _datasource.getProducts(queryParameters: filters);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ProductEntity> getProductDetails(String productId) async {
    final model = await _datasource.getProductDetails(productId);
    return model.toEntity();
  }
}
