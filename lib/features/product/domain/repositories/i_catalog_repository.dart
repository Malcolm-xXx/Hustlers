import '../entities/category_entity.dart';
import '../entities/product_entity.dart';
import '../entities/tag_entity.dart';

abstract class ICatalogRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<List<TagEntity>> getTags();
  Future<List<ProductEntity>> getProducts({Map<String, dynamic>? filters});
  Future<ProductEntity> getProductDetails(String productId);
}
