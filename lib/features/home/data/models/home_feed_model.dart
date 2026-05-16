import '../../../product/data/models/category_model.dart';
import '../../../product/data/models/product_model.dart';
import '../../domain/entities/home_feed_entity.dart';
import 'seller_model.dart';

class HomeFeedModel {
  final List<CategoryModel> categories;
  final List<SellerModel> topSellers;
  final List<ProductModel> featuredProducts;

  const HomeFeedModel({
    this.categories = const [],
    this.topSellers = const [],
    this.featuredProducts = const [],
  });

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) {
    return HomeFeedModel(
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topSellers: (json['top_sellers'] as List<dynamic>?)
              ?.map((e) => SellerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      featuredProducts: (json['featured_products'] as List<dynamic>?)
              ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  HomeFeedEntity toEntity() => HomeFeedEntity(
        categories: categories.map((e) => e.toEntity()).toList(),
        topSellers: topSellers.map((e) => e.toEntity()).toList(),
        featuredProducts: featuredProducts.map((e) => e.toEntity()).toList(),
      );
}
