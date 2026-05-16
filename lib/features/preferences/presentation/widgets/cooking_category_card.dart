import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';

class CookingCategoryCard extends StatelessWidget {
  final String title;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CookingCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.secondary500 : AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary500
                : AppColors.fieldBorderInactive.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white.withOpacity(0.15)
                    : AppColors.white.withOpacity(0.8),

                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Image.asset(
                icon,
                fit: BoxFit.cover,
                color: isSelected
                    ? null
                    : Colors.grey.withOpacity(0.6),
                colorBlendMode: isSelected ? null : BlendMode.modulate,
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                title,
                style: AppTextStyle.bodySm.copyWith(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
