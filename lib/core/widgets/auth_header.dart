import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hustlers/core/constants/app_text_style.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final VoidCallback? onBack;

  const AuthHeader({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 15.w, bottom: 17.h),

          child: GestureDetector(
            onTap: onBack ?? () => context.pop(),
            child: SvgPicture.asset(
              AppAssets.iconBack,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18.5.h),
              child: Text(
                'Hustler',
                style: AppTextStyle.displayLg.copyWith(
                  fontSize: 30.sp,
                  color: AppColors.primary500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}
