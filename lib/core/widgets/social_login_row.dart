import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hustlers/core/constants/app_text_style.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

class SocialLoginRow extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onFacebookTap;

  const SocialLoginRow({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
    this.onFacebookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: _SocialButton(
            assetPath: AppAssets.icGoogle,
            title: 'Google',
            onTap: onGoogleTap,
          ),
        ),
        SizedBox(width: 5.w),
        Flexible(
          child: _SocialButton(
            assetPath: AppAssets.apple,
            title: 'Apple',
            onTap: onAppleTap,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String assetPath;
  final String title;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.assetPath,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Center(
          child: Row(
            children: [
              SvgPicture.asset(
                assetPath,
                // width: 24,
                // height: 24,
              ),
              SizedBox(width: 20.w,),
              Text(
                title,
                style: AppTextStyle.bodyLg.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w500
                ),

              )
            ],
          ),
        ),
      ),
    );
  }
}
