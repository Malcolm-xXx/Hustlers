import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/profile_notifier.dart';
import '../providers/profile_state.dart';
import 'buyer_profile_view.dart';
import 'seller_profile_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isSeller = profile.currentRole == UserRole.seller;

    return Scaffold(
      backgroundColor: AppColors.profileHeaderBg,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: Colors.white,
          child: isSeller
              ? const SellerProfileView()
              : const BuyerProfileView(),
        ),
      ),
    );
  }
}
