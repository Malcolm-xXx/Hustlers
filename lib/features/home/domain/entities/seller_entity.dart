class SellerEntity {
  final String id;
  final String name;
  final String? profileImageUrl;
  final double rating;
  final int totalReviews;
  final String status;
  final String distance;
  final List<String> tags;

  const SellerEntity({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.status = '',
    this.distance = '',
    this.tags = const [],
  });
}
