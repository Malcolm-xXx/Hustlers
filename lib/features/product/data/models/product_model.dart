import '../../../home/data/models/seller_model.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel {
  final String id;
  final String name; // maps to title
  final double price;
  final double? originalPrice;
  final String unit;
  final String storeName; // maps to seller.name
  final double storeRating; // maps to seller.rating or rating
  final bool isVerified;
  final String description;
  final String shelfLife;
  final String imageUrl;
  final String? badge;
  final String? badgeColor;
  final SellerModel? seller;
  final int inventory;
  final bool inStock;
  final List<String> tags;
  final List<String> categories;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.unit = 'Item',
    this.storeName = '',
    this.storeRating = 0.0,
    this.isVerified = true,
    this.description = '',
    this.shelfLife = '',
    this.imageUrl = '',
    this.badge,
    this.badgeColor,
    this.seller,
    this.inventory = 0,
    this.inStock = true,
    this.tags = const [],
    this.categories = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse currency strings like "₦1,500.00" or plain numbers
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    final basePrice = parsePrice(json['base_price'] ?? json['price']);
    final discountedPrice = parsePrice(json['discounted_price']);
    final isOnSale = json['is_on_sale'] ?? (json['original_price'] != null);

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      price: (isOnSale && discountedPrice > 0) ? discountedPrice : basePrice,
      originalPrice: isOnSale ? basePrice : null,
      unit: json['unit_label'] ?? json['unit'] ?? 'Item',
      storeName: json['seller']?['store_name'] ?? json['seller']?['name'] ?? 'Unknown Store',
      storeRating: (json['rating'] ?? json['seller']?['rating'] ?? 0.0).toDouble(),
      isVerified: json['seller']?['is_verified'] ?? false,
      shelfLife: json['shelf_life'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=600',
      seller: json['seller'] != null ? SellerModel.fromJson(json['seller']) : null,
      inventory: json['inventory'] ?? 0,
      inStock: json['in_stock'] ?? json['inStock'] ?? true,
      tags: List<String>.from(json['tags'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  ProductEntity toEntity() => ProductEntity(
        id: id,
        title: name,
        description: description,
        price: price,
        originalPrice: originalPrice,
        currency: 'NGN',
        seller: seller?.toEntity(),
        inventory: inventory,
        rating: storeRating,
        inStock: inStock,
        tags: tags,
        categories: categories,
        unit: unit,
        shelfLife: shelfLife,
        imageUrl: imageUrl,
        badge: badge,
      );

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  // Mock products for UI development
  static List<ProductModel> mockProducts = [
    const ProductModel(
      id: '1',
      name: 'White Garri',
      price: 500,
      unit: 'Congo',
      storeName: 'Ifeanyi Bulk Store',
      storeRating: 4.1,
      isVerified: true,
      description:
          'Clean, stone-free, and crispy! Fresh from the perfect "soap" and soak! Whether you\'re looking for a quick meal or making a smooth eba, this garri is properly processed to give you that classic tangy taste without the hassle.',
      shelfLife: '3 months if kept in a cool, dry place away from moisture',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=600',
      badge: 'Few Left',
    ),
    const ProductModel(
      id: '2',
      name: 'Foreign Rice',
      price: 1500,
      unit: 'Bag',
      storeName: 'Mama Ngozi Store',
      storeRating: 4.5,
      isVerified: true,
      description:
          'Premium quality foreign rice, long grain and aromatic. Perfect for jollof, fried rice, or white rice. Clean and stone-free.',
      shelfLife: '6 months in sealed container',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=600',
      badge: 'New',
    ),
    const ProductModel(
      id: '3',
      name: 'Brown Beans',
      price: 1500,
      unit: 'Congo',
      storeName: 'Campus Store',
      storeRating: 3.9,
      isVerified: false,
      description:
          'Fresh brown beans, sorted and clean. Great for cooking porridge beans, moi-moi or akara.',
      shelfLife: '4 months if stored properly',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=600',
      badge: 'Few Left',
    ),
    const ProductModel(
      id: '4',
      name: 'Local Rice',
      price: 1100,
      unit: 'Congo',
      storeName: 'Ifeanyi Bulk Store',
      storeRating: 4.1,
      isVerified: true,
      description:
          'Locally sourced and well processed rice. Clean and ready to cook. Ideal for daily meals.',
      shelfLife: '5 months in dry storage',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=600',
      badge: 'Few Left',
    ),
    const ProductModel(
      id: '5',
      name: 'White Garri',
      price: 450,
      originalPrice: 600,
      unit: 'Congo',
      storeName: 'Ifeanyi Bulk Store',
      storeRating: 4.1,
      isVerified: true,
      description:
          'Clean, stone-free, and crispy! Fresh from the perfect "soap" and soak! Whether you\'re looking for a quick meal or making a smooth eba, this garri is properly processed to give you that classic tangy taste without the hassle.',
      shelfLife: '3 months if kept in a cool, dry place away from moisture',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=600',
      badge: 'Combo',
    ),
  ];
}
