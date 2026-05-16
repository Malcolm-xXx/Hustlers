import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class ProfileLogOutButton extends StatelessWidget {
  final VoidCallback? onTap;

  const ProfileLogOutButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(
            Icons.logout_rounded,
            size: 20.sp,
            color: AppColors.logOutRed,
          ),
          label: Text(
            'Log Out',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.logOutRed,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.logOutBg,
            side: BorderSide(color: AppColors.logOutBorder, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 16.h),
          ),
        ),
      ),
    );
  }
}
