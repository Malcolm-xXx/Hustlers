import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool showDivider;
  final Widget? trailingBadge;
  final String? trailingText;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.showDivider = true,
    this.trailingBadge,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: showDivider
          ? BorderRadius.zero
          : BorderRadius.only(
              bottomLeft: Radius.circular(12.r),
              bottomRight: Radius.circular(12.r),
            ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            child: Row(
              children: [
                Icon(icon, color: AppColors.menuIconGrey, size: 22.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.profileText,
                    ),
                  ),
                ),
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.starYellow,
                    ),
                  ),
                ?trailingBadge,
                if (trailingBadge != null || trailingText != null)
                  SizedBox(width: 12.w),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.chevronGrey,
                  size: 20.sp,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.menuDivider,
              indent: 54.w,
              endIndent: 16.w,
            ),
        ],
      ),
    );
  }
}
