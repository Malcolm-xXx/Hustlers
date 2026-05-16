import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class RoleSwitchBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSwitch;

  const RoleSwitchBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: AppColors.profileNavyCard,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          GestureDetector(
            onTap: onSwitch,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
