import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_assets.dart';

class TitleSegment {
  final String text;
  final bool isHighlighted;

  const TitleSegment(this.text, {this.isHighlighted = false});
}

class OnboardingPageModel {
  final List<TitleSegment> titleSegments;
  final String description;
  final String? asset;
  final double height;
  final double radius;
  final double width;

  const OnboardingPageModel({
    required this.titleSegments,
    required this.description,
    this.asset,
    required this.height,
    required this.radius,
    required this.width,
  });

  static final List<OnboardingPageModel> defaultPages = [
    OnboardingPageModel(
      titleSegments: [
        const TitleSegment('Skip the Market Stress\n'),
        const TitleSegment('Shop Raw, Shop Verified.', isHighlighted: true),
      ],
      description:
          'Avoid the market crowds. Order quality raw food essentials from trusted vendors in just a few taps.',
      asset: AppAssets.onboarding1,
      height: 440.h,
      radius: 119.r,
      width: 358.w,
    ),
    OnboardingPageModel(
      titleSegments: [
        const TitleSegment('Verified Sellers,', isHighlighted: true),
        const TitleSegment(' Quality Guaranteed.'),
      ],
      description:
          'Every "hustler" on our platform goes through a strict verification process . Shop with confidence knowing your food comes from trusted local hands.',
      asset: AppAssets.onboarding2,
      height: 384.h,
      radius: 85.r,
      width: 370.w,
    ),
    OnboardingPageModel(
      titleSegments: [
        const TitleSegment('Track', isHighlighted: true),
        const TitleSegment(' Every Step.'),
      ],
      description:
          'Every "hustler" on our platform goes through a strict verification process . Shop with confidence knowing your food comes from trusted local hands.',
      asset: AppAssets.onboarding3,
      height: 391.h,
      radius: 83.r,
      width: 370.w,
    ),
  ];
}
