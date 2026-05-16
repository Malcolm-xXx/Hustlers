import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_state.dart';

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState();
  }

  void switchRole() {
    final newRole = state.currentRole == UserRole.buyer
        ? UserRole.seller
        : UserRole.buyer;
    state = state.copyWith(currentRole: newRole);
  }

  void toggleShopStatus() {
    state = state.copyWith(isShopActive: !state.isShopActive);
  }

  void dismissSellerBanner() {
    state = state.copyWith(showSellerBanner: false);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
