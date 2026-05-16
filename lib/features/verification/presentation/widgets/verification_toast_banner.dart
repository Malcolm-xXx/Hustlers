import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/verification_provider.dart';

class VerificationToastBanner extends StatelessWidget {
  final BannerState banner;
  final VoidCallback onDismiss;

  const VerificationToastBanner({
    super.key,
    required this.banner,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = banner.type == BannerType.success;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.successBg : AppColors.errorBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.successIcon : AppColors.errorIcon,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.priority_high,
              color: AppColors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  banner.title,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  banner.message,
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 20.sp,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
