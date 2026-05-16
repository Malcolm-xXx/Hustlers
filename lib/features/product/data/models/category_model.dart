import '../../domain/entities/category_entity.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconUrl: json['icon_url'] ?? json['iconUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon_url': iconUrl,
      };

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        name: name,
        iconUrl: iconUrl,
      );
}
