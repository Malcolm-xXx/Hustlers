import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hustlers/core/constants/app_assets.dart';
import 'package:hustlers/core/constants/app_colors.dart';
import 'package:hustlers/core/constants/app_text_style.dart';
import 'package:hustlers/core/navigation/route_names.dart';
import 'package:hustlers/features/profile/presentation/providers/profile_notifier.dart';
import 'package:hustlers/features/profile/presentation/providers/profile_state.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool isWalletExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=11',
                    ), // Placeholder avatar
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Username Here',
                    style: AppTextStyle.headingSm.copyWith(fontSize: 16.sp),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Standard User',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Switch to Seller mode',
                        style: AppTextStyle.bodyMd.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 16.sp,
                          color: AppColors.secondary500
                        ),
                      ),
                      SizedBox(width: 8.w,),
                      CupertinoSwitch(
                        value: ref.watch(profileProvider).currentRole ==
                            UserRole.seller,
                        onChanged: (value) {
                          Navigator.of(context).pop();
                          ref.read(profileProvider.notifier).switchRole();
                          if (value) {
                            context.goNamed(RouteNames.sellerHome);
                          } else {
                            context.goNamed(RouteNames.home);
                          }
                        },
                        activeColor: const Color(0xFF1B1A28),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(
              color: Color(0XFFE2E4E5),
              thickness: 1,
              height: 1,
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: AppAssets.stash,
                        title: 'Stash',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: AppAssets.hustles,
                        title: 'My Hustles',
                        onTap: () {},
                      ),
                      _buildExpandableWalletItem(),
                      _buildMenuItem(
                        icon: AppAssets.notification,
                        title: 'Notifications',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: AppAssets.chat,
                        title: 'Chats',
                        onTap: () {
                          context.pushNamed(RouteNames.sellerChats);
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: Color(0XFFE2E4E5),
                          thickness: 1,
                          height: 1,
                        ),
                      ),

                      _buildMenuItem(
                        icon: AppAssets.savedHustlers,
                        title: 'Saved Hustlers',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: AppAssets.location,
                        title: 'Saved Locations',
                        onTap: () {},
                      ),

                      _buildVerificationBanner(),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: Color(0XFFE2E4E5),
                          thickness: 1,
                          height: 1,
                        ),
                      ),

                      _buildMenuItem(
                        icon: AppAssets.settings,
                        title: 'Settings',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: AppAssets.help,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: AppAssets.logout,
                        title: 'Logout',
                        iconColor: AppColors.logOutRed,
                        textColor: AppColors.logOutRed,
                        onTap: () {},
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF1B1A28),
    Color textColor = AppColors.textDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            SvgPicture.asset(icon),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTextStyle.bodyMd.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableWalletItem() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              isWalletExpanded = !isWalletExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                SvgPicture.asset(AppAssets.wallet),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Wallet',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  isWalletExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF1B1A28),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (isWalletExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 24, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '₦1,500',
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Top Up',
                      style: AppTextStyle.bodySm.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Transaction History',
                      style: AppTextStyle.bodySm.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 12.52),
            spreadRadius: 0,
            blurRadius: 10.02,
            color: Color(0XFF6154AA).withOpacity(0.065)
          )
        ],
        // gradient: const LinearGradient(
        //   colors: [Color(0xFF0F1B2B), Color(0xFF003058)],
        //   begin: Alignment.bottomLeft,
        //   end: Alignment.topRight,
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Earning on Hustler',
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120.w,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26.r)
            ),
            child: Row(
              children: [
                SvgPicture.asset(AppAssets.shield),
                SizedBox(width: 2,),
                Text(
                  'Get Verified',
                  style: AppTextStyle.bodySm.copyWith(
                      color: Color(0XFF001F3F),
                    fontSize: 11.sp
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
