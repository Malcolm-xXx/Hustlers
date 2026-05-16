enum UserRole { buyer, seller }

enum BuyerVerificationStatus { unverified, verified }

class ProfileState {
  final UserRole currentRole;
  final BuyerVerificationStatus buyerVerificationStatus;
  final bool showSellerBanner;
  final bool isShopActive;

  // User display data
  final String userName;
  final String avatarUrl;
  final double rating;
  final int orderCount;
  final int reviewCount;
  final double earnings;

  const ProfileState({
    this.currentRole = UserRole.buyer,
    this.buyerVerificationStatus = BuyerVerificationStatus.verified,
    this.showSellerBanner = true,
    this.isShopActive = true,
    this.userName = 'Wellens Rufus',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1531123897727-8f129e1bf98a?q=80&w=250&auto=format&fit=crop',
    this.rating = 4.8,
    this.orderCount = 120,
    this.reviewCount = 120,
    this.earnings = 1240.50,
  });

  ProfileState copyWith({
    UserRole? currentRole,
    BuyerVerificationStatus? buyerVerificationStatus,
    bool? showSellerBanner,
    bool? isShopActive,
    String? userName,
    String? avatarUrl,
    double? rating,
    int? orderCount,
    int? reviewCount,
    double? earnings,
  }) {
    return ProfileState(
      currentRole: currentRole ?? this.currentRole,
      buyerVerificationStatus:
          buyerVerificationStatus ?? this.buyerVerificationStatus,
      showSellerBanner: showSellerBanner ?? this.showSellerBanner,
      isShopActive: isShopActive ?? this.isShopActive,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      orderCount: orderCount ?? this.orderCount,
      reviewCount: reviewCount ?? this.reviewCount,
      earnings: earnings ?? this.earnings,
    );
  }
}
