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

class SellerProfileView extends ConsumerWidget {
  const SellerProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (centered layout) ──
          _buildHeader(context, profile),

          // ── Switch to Buyer Banner ──
          RoleSwitchBanner(
            title: 'Switch to Buyer View',
            subtitle: 'Browse food as a customer',
            onSwitch: () => ref.read(profileProvider.notifier).switchRole(),
          ),

          // ── Shop Status ──
          _buildShopStatusCard(ref, profile),

          SizedBox(height: 8.h),

          // ── Account Menu ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileSectionTitle(title: 'ACCOUNT'),
                ProfileMenuCard(
                  children: [
                    ProfileMenuItem(
                      icon: Icons.access_time,
                      title: 'Business Hours',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.map_outlined,
                      title: 'Service Area',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.grid_view_rounded,
                      title: 'Listings',
                      onTap: () {},
                    ),
                    ProfileMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Earnings',
                      showDivider: false,
                      trailingText: '\$${profile.earnings.toStringAsFixed(2)}',
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

  Widget _buildHeader(BuildContext context, ProfileState profile) {
    return Container(
      width: double.infinity,
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
      child: Stack(
        children: [
          // Center content
          Column(
            children: [
              SizedBox(height: 8.h),
              // Avatar
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: DecorationImage(
                    image: NetworkImage(profile.avatarUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Name
              Text(
                profile.userName,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.profileText,
                ),
              ),
              SizedBox(height: 6.h),

              // Verified Seller badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.verifiedGreen),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  'Verified Seller',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.verifiedGreen,
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  SizedBox(width: 4.w),
                  Text(
                    '(${profile.reviewCount} reviews)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.sectionTitleGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Share icon (top-right)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {},
              child: Icon(
                Icons.ios_share_outlined,
                size: 24.sp,
                color: AppColors.profileText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStatusCard(WidgetRef ref, ProfileState profile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.menuBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop Status',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.profileText,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  profile.isShopActive
                      ? 'Currently accepting orders'
                      : 'Not accepting orders',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.sectionTitleGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: profile.isShopActive,
            onChanged: (_) =>
                ref.read(profileProvider.notifier).toggleShopStatus(),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.starYellow,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.sectionTitleGrey,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
