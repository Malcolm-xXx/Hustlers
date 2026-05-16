import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hustlers/core/constants/app_assets.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';


class HomeAppBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const HomeAppBar({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Drawer Icon
          GestureDetector(
            onTap: () {
              scaffoldKey.currentState?.openDrawer();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white50),
              ),
              child: const Icon(Icons.menu, color: AppColors.textDark),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.grey400
                ),
              ),
              Row(
                children: [
                  Text(
                    'Bank 1656 Union St...',
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary500
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ],
          ),

          GestureDetector(
            onTap: () => context.pushNamed(RouteNames.notifications),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.white50),
              ),
              child: SvgPicture.asset(AppAssets.notificationIcon)
            ),
          ),
        ],
      ),
    );
  }
}
