import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

class AppTextStyle {
  AppTextStyle._();

  static TextStyle displayLg = TextStyle(
    fontFamily: 'BraveHunter',
    fontSize: 48.sp,
    color: AppColors.primary500,
    letterSpacing: -0.2
  );

  static TextStyle headingLg = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 23.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.secondary400,
    height: 1.4,
    letterSpacing: -0.2,
  );

  static TextStyle headingMd = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static TextStyle headingSm = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.3,
  );

  static TextStyle bodyLg = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.secondary500,
    height: 1.4,
  );

  static TextStyle bodyMd = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
    height: 1.4,
  );

  static TextStyle bodySm = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    height: 1.5,
  );

  static TextStyle labelLg = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    overflow: TextOverflow.ellipsis,
  );

  static TextStyle labelMd = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
    overflow: TextOverflow.ellipsis,
  );

  static TextStyle labelSm = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13.sp,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary400,
    overflow: TextOverflow.ellipsis,
  );

  static TextStyle hint = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.black.withOpacity(0.38),
    overflow: TextOverflow.ellipsis,
  );


  static TextStyle link = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.primary500,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary500,
  );
}
