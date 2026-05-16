import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../providers/profile_notifier.dart';
import '../providers/profile_state.dart';
import '../widgets/profile_log_out_button.dart';
import '../widgets/profile_menu_card.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_section_title.dart';
import '../widgets/role_switch_banner.dart';
import '../widgets/seller_verification_banner.dart';

class BuyerProfileView extends ConsumerWidget {
  const BuyerProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isVerified =
        profile.buyerVerificationStatus == BuyerVerificationStatus.verified;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(profile),

          if (isVerified)
            RoleSwitchBanner(
              title: 'Switch to Seller Mode',
              subtitle: 'Sell food to buyers on hustlers',
              onSwitch: () => ref.read(profileProvider.notifier).switchRole(),
            )
          else if (profile.showSellerBanner)
            SellerVerificationBanner(
              onGetVerified: () {
                context.pushNamed(RouteNames.idVerification);
              },
              onDismiss: () =>
                  ref.read(profileProvider.notifier).dismissSellerBanner(),
            ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isVerified && !profile.showSellerBanner)
                  SizedBox(height: 24.h),

                // Account
                const ProfileSectionTitle(title: 'ACCOUNT'),
                ProfileMenuCard(
                  children: [
                    ProfileMenuItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Become a Seller',
                      showDivider: false,
                      trailingBadge: _buildNewBadge(),
                      onTap: () {},
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Activity
                const ProfileSectionTitle(title: 'ACTIVITY'),
                ProfileMenuCard(
                  children: [
                    ProfileMenuItem(
                      icon: Icons.favorite_border,
                      title: 'Favorites',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Order History',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.star_border,
                      title: 'Reviews Given',
                      showDivider: false,
                      onTap: () {},
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Settings
                const ProfileSectionTitle(title: 'SETTINGS'),
                ProfileMenuCard(
                  children: [
                    ProfileMenuItem(
                      icon: Icons.notifications_none,
                      title: 'Notification Settings',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.shield_outlined,
                      title: 'Security Settings',
                      showDivider: false,
                      onTap: () {},
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Support & Legal
                const ProfileSectionTitle(title: 'SUPPORT & LEGAL'),
                ProfileMenuCard(
                  children: [
                    ProfileMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.local_police_outlined,
                      title: 'Legal',
                      showDivider: false,
                      onTap: () {},
                    ),
                  ],
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),

          // ── Log Out ──
          ProfileLogOutButton(
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.goNamed(RouteNames.signIn);
            },
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildHeader(ProfileState profile) {
    return Container(
      padding: EdgeInsets.only(
        top: 20.h,
        left: 24.w,
        right: 24.w,
        bottom: 30.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.profileHeaderBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              image: DecorationImage(
                image: NetworkImage(profile.avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // Name + badge + stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    profile.userName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.profileText,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.verifiedGreen),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'Buyer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.verifiedGreen,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.starYellow, size: 18.sp),
                  SizedBox(width: 4.w),
                  Text(
                    profile.rating.toString(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.profileText,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.shopping_bag,
                    color: AppColors.profileText,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    profile.orderCount.toString(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.profileText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.starYellow,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'New',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
