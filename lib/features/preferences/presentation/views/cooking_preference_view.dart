import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hustlers/core/constants/app_assets.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/auth_header.dart';
import '../providers/preferences_provider.dart';
import '../widgets/cooking_category_card.dart';
import '../widgets/preference_progress_bar.dart';

class CookingPreferenceView extends ConsumerWidget {
  const CookingPreferenceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthHeader(),
              const PreferenceProgressBar(currentStep: 1),
              SizedBox(height: 32.h),
              Text(
                'What do you cook most often?',
                style: AppTextStyle.headingLg.copyWith(
                  fontSize: 22.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20.w,
                  mainAxisSpacing: 30.h,
                  childAspectRatio: 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    CookingCategoryCard(
                      title: 'Grains & Tubers',
                      icon: AppAssets.cookingPref,
                      isSelected:
                          state.cookingPreference == 'grains_tubers',
                      onTap: () => notifier
                          .selectCookingPreference('grains_tubers'),
                    ),
                    CookingCategoryCard(
                      title: 'Fresh Veggies & Fruit',
                      icon: AppAssets.cookingPref,
                      isSelected:
                          state.cookingPreference == 'veggies_fruit',
                      onTap: () => notifier
                          .selectCookingPreference('veggies_fruit'),
                    ),
                    CookingCategoryCard(
                      title: 'Proteins\n(Meat/Fish/Eggs)',
                      icon: AppAssets.cookingPref,
                      isSelected:
                          state.cookingPreference == 'proteins',
                      onTap: () =>
                          notifier.selectCookingPreference('proteins'),
                    ),
                    CookingCategoryCard(
                      title: 'Everything',
                      icon: AppAssets.cookingPref,
                      isSelected:
                          state.cookingPreference == 'everything',
                      onTap: () => notifier
                          .selectCookingPreference('everything'),
                    ),
                  ],
                ),
              ),
              AppPrimaryButton(
                text: 'Next',
                isLoading: state.isLoading,
                onPressed: state.isCookingPreferenceSelected
                    ? () => notifier.navigateToSetLocation(context)
                    : null,
                backgroundColor: state.isCookingPreferenceSelected
                    ? AppColors.secondary500
                    : AppColors.buttonDisabled,
                disabledBackgroundColor: AppColors.buttonDisabled,
                disabledForegroundColor: AppColors.white,
                borderRadius: 26.r,
                height: 52.h,
              ),
              SizedBox(height: 12.h),
              Center(
                child: GestureDetector(
                  onTap: () => notifier.skipToNext(context),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'Skip',
                      style: AppTextStyle.labelMd.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
