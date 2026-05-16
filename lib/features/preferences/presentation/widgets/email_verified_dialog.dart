import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';

class EmailVerifiedDialog extends StatelessWidget {
  final VoidCallback onSetPreferences;

  const EmailVerifiedDialog({super.key, required this.onSetPreferences});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onSetPreferences,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) =>
          EmailVerifiedDialog(onSetPreferences: onSetPreferences),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            SizedBox(height: 24.h),
            Text(
              'Email Verified!',
              style: AppTextStyle.headingLg.copyWith(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Let's set up Your preferences to personalize\nYour experience",
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.textGrey,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            AppPrimaryButton(
              text: 'Set My Preferences',
              onPressed: onSetPreferences,
              backgroundColor: AppColors.secondary500,
              borderRadius: 26.r,
              height: 52.h,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 90.w,
      height: 90.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary500.withOpacity(0.35),
            AppColors.primary500.withOpacity(0.08),
            Colors.transparent,
          ],
          stops: const [0.4, 0.7, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary500,
          ),
          child: Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.white,
            size: 28.sp,
          ),
        ),
      ),
    );
  }
}
