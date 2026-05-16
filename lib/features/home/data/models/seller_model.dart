import '../../domain/entities/seller_entity.dart';

class SellerModel {
  final String id;
  final String name;
  final String? profileImageUrl;
  final double rating;
  final int totalReviews;
  final String status;
  final String distance;
  final List<String> tags;

  const SellerModel({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.status = '',
    this.distance = '',
    this.tags = const [],
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id']?.toString() ?? '',
      name: json['store_name'] ?? json['name'] ?? '',
      profileImageUrl: json['profile_image'] ?? json['profile_image_url'] ?? json['profileImageUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['rating_count'] ?? json['total_reviews'] ?? json['totalReviews'] ?? 0,
      status: json['status'] ?? '',
      distance: json['distance_km']?.toString() ?? json['distance']?.toString() ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profile_image_url': profileImageUrl,
        'rating': rating,
        'total_reviews': totalReviews,
        'status': status,
        'distance': distance,
        'tags': tags,
      };

  SellerEntity toEntity() => SellerEntity(
        id: id,
        name: name,
        profileImageUrl: profileImageUrl,
        rating: rating,
        totalReviews: totalReviews,
        status: status,
        distance: distance,
        tags: tags,
      );

  static const List<SellerModel> mockSellers = [
    SellerModel(
      id: 's1',
      name: 'Chinyere\'s Kitchen',
      profileImageUrl: 'https://i.pravatar.cc/150?img=5',
      rating: 4.8,
      totalReviews: 230,
      status: 'Available',
      distance: '0.3 km',
      tags: ['Jollof Rice', 'Swallow', 'Soups'],
    ),
    SellerModel(
      id: 's2',
      name: 'Emeka Bulk Store',
      profileImageUrl: 'https://i.pravatar.cc/150?img=11',
      rating: 4.5,
      totalReviews: 182,
      status: 'In Market',
      distance: '0.8 km',
      tags: ['Grains', 'Rice', 'Beans'],
    ),
    SellerModel(
      id: 's3',
      name: 'Amaka Fresh Farm',
      profileImageUrl: 'https://i.pravatar.cc/150?img=9',
      rating: 4.2,
      totalReviews: 95,
      status: 'Available',
      distance: '1.1 km',
      tags: ['Vegetables', 'Tomatoes', 'Peppers'],
    ),
    SellerModel(
      id: 's4',
      name: 'Tunde\'s Provisions',
      profileImageUrl: 'https://i.pravatar.cc/150?img=15',
      rating: 3.9,
      totalReviews: 64,
      status: 'Available',
      distance: '1.5 km',
      tags: ['Provisions', 'Drinks', 'Snacks'],
    ),
  ];
}
