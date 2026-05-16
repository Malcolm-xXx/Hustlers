import '../../domain/entities/tag_entity.dart';

class TagModel {
  final String id;
  final String name;

  const TagModel({
    required this.id,
    required this.name,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  TagEntity toEntity() => TagEntity(
        id: id,
        name: name,
      );
}
