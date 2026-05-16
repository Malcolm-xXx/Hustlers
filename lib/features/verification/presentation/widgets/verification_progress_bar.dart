import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class VerificationProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const VerificationProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index <= currentStep;
          return Expanded(
            child: Container(
              height: 4.h,
              margin: EdgeInsets.only(
                right: index < totalSteps - 1 ? 8.w : 0,
              ),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary500 : AppColors.progressInactive,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          );
        }),
      ),
    );
  }
}
