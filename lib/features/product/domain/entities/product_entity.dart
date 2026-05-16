import '../../../home/domain/entities/seller_entity.dart';

class ProductEntity {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final String currency;
  final SellerEntity? seller;
  final int inventory;
  final double rating;
  final bool inStock;
  final List<String> tags;
  final String unit;
  final String? shelfLife;
  final List<String> categories;
  final String? imageUrl;
  final String? badge;

  const ProductEntity({
    required this.id,
    required this.title,
    this.description = '',
    this.price = 0.0,
    this.originalPrice,
    this.currency = 'USD',
    this.seller,
    this.inventory = 0,
    this.rating = 0.0,
    this.inStock = false,
    this.tags = const [],
    this.categories = const [],
    this.unit = 'Item',
    this.shelfLife,
    this.imageUrl,
    this.badge,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }
}
