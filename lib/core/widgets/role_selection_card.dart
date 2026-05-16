import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hustlers/core/constants/app_text_style.dart';

import '../constants/app_colors.dart';

class RoleSelectionCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final String icon;
  final VoidCallback onTap;

  const RoleSelectionCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkButton : AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.darkButton : AppColors.fieldBorderInactive.withOpacity(0.22),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [

            SvgPicture.asset(
                icon,
              colorFilter: isSelected? ColorFilter.mode(AppColors.primary500, BlendMode.srcIn): null,
            ),
            SizedBox(width: 15.w,),
            Text(
              title,
              style: AppTextStyle.bodyLg.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppColors.white : AppColors.secondary400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
