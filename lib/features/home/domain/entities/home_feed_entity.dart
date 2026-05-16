import '../../../product/domain/entities/category_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import 'seller_entity.dart';

class HomeFeedEntity {
  final List<CategoryEntity> categories;
  final List<SellerEntity> topSellers;
  final List<ProductEntity> featuredProducts;

  const HomeFeedEntity({
    this.categories = const [],
    this.topSellers = const [],
    this.featuredProducts = const [],
  });
}
