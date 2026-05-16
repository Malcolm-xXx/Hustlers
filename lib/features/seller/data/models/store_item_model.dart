import '../../../product/domain/entities/product_entity.dart';

class StoreItemModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final double? salePrice;
  final String unit;
  final String description;
  final String shelfLife;
  final String imageUrl;
  final bool inStock;
  final bool isDraft;
  final DateTime createdAt;

  const StoreItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.salePrice,
    required this.unit,
    this.description = '',
    this.shelfLife = '',
    this.imageUrl = '',
    this.inStock = true,
    this.isDraft = false,
    required this.createdAt,
  });

  bool get isOnSale => salePrice != null && salePrice! < price;

  double get discountPercentage {
    if (!isOnSale) return 0;
    return ((price - salePrice!) / price * 100).roundToDouble();
  }

  factory StoreItemModel.fromEntity(ProductEntity entity) {
    return StoreItemModel(
      id: entity.id,
      name: entity.title,
      category: entity.categories.isNotEmpty ? entity.categories.first : (entity.tags.isNotEmpty ? entity.tags.first : 'General'),
      price: entity.price,
      unit: entity.unit,
      description: entity.description,
      shelfLife: entity.shelfLife ?? '',
      imageUrl: entity.imageUrl ?? '',
      inStock: entity.inStock,
      createdAt: DateTime.now(), // Fallback as entity lacks createdAt
    );
  }

  StoreItemModel copyWith({
    String? name,
    String? category,
    double? price,
    double? salePrice,
    bool clearSalePrice = false,
    String? unit,
    String? description,
    String? shelfLife,
    String? imageUrl,
    bool? inStock,
    bool? isDraft,
  }) {
    return StoreItemModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      salePrice: clearSalePrice ? null : (salePrice ?? this.salePrice),
      unit: unit ?? this.unit,
      description: description ?? this.description,
      shelfLife: shelfLife ?? this.shelfLife,
      imageUrl: imageUrl ?? this.imageUrl,
      inStock: inStock ?? this.inStock,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt,
    );
  }

  static List<StoreItemModel> mockItems = [
    StoreItemModel(
      id: '1',
      name: 'White Garri',
      category: 'Grains',
      price: 500,
      unit: 'Per Congo',
      description: 'Clean stone-free garri',
      shelfLife: '3 months',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=150',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    StoreItemModel(
      id: '2',
      name: 'Foreign Rice',
      category: 'Grains',
      price: 1500,
      unit: 'Per Congo',
      description: 'Premium long grain rice',
      shelfLife: '6 months',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=150',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    StoreItemModel(
      id: '3',
      name: 'Local Rice',
      category: 'Grains',
      price: 1000,
      unit: 'Per Congo',
      description: 'Locally sourced rice',
      shelfLife: '5 months',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=150',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    StoreItemModel(
      id: '4',
      name: 'Brown Beans',
      category: 'Grains',
      price: 1500,
      unit: 'Per Congo',
      description: 'Sorted fresh brown beans with no stone',
      shelfLife: '6 months if kept in cool and dry place',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=150',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StoreItemModel(
      id: '5',
      name: 'White Beans',
      category: 'Grains',
      price: 1500,
      unit: 'Per Congo',
      description: 'Clean white beans',
      shelfLife: '4 months',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=150',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StoreItemModel(
      id: '6',
      name: 'Yellow Garri',
      category: 'Grains',
      price: 500,
      unit: 'Per Congo',
      description: 'Yellow garri, fresh and crispy',
      shelfLife: '3 months',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=150',
      createdAt: DateTime.now(),
    ),
  ];

  static StoreItemModel mockDraft = StoreItemModel(
    id: 'draft1',
    name: 'Brown Beans',
    category: 'Grains',
    price: 1500,
    unit: 'Per Congo',
    isDraft: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}
