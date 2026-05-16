import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';

class PreferenceOptionTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const PreferenceOptionTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary500 : AppColors.grey50,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary500
                : AppColors.fieldBorderInactive.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildRadio(),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyle.labelMd.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.white : AppColors.textDark,
          width: isSelected ? 2 : 1.5,
        ),
        color: isSelected ? Colors.transparent : Colors.transparent,
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
              ),
            )
          : null,
    );
  }
}
