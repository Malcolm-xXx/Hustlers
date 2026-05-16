import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/onboarding_page_model.dart';

class OnboardingPageWidget extends StatelessWidget {
  final List<TitleSegment> titleSegments;
  final String description;
  final String? asset;
  final double height;
  final double radius;
  final double width;

  const OnboardingPageWidget({
    super.key,
    required this.titleSegments,
    required this.description,
    this.asset,
    required this.height,
    required this.radius,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            asset!,
            height: height,
            width: width,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyle.headingLg.copyWith(
                    fontSize: 28.sp,
                    letterSpacing: 0,
                    fontFamily: 'Poppins',
                    height: 1.4
                  ),
                  children: titleSegments.map((segment) {
                    return TextSpan(
                      text: segment.text,
                      style: segment.isHighlighted
                          ? const TextStyle(color: AppColors.primary500)
                          : null,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyle.bodyMd,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
