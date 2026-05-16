import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/auth_header.dart';
import '../providers/preferences_provider.dart';
import '../widgets/preference_option_tile.dart';
import '../widgets/preference_progress_bar.dart';

class PrimaryGoalView extends ConsumerWidget {
  const PrimaryGoalView({super.key});

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
              SizedBox(height: 20.h,),
              AuthHeader(
                onBack: (){
                  try{
                    context.pop();
                  }catch(e){
                    context.goNamed(RouteNames.signIn);
                  }
                },
              ),
              const PreferenceProgressBar(currentStep: 0),
              SizedBox(height: 45.h),
              Text(
                "What's your primary goal?",
                style: AppTextStyle.headingLg.copyWith(
                  fontSize: 22.sp,
                ),
              ),
              SizedBox(height: 36.h),
              PreferenceOptionTile(
                title: 'Stocking my kitchen',
                isSelected: state.primaryGoal == 'stocking_kitchen',
                onTap: () => notifier.selectPrimaryGoal('stocking_kitchen'),
              ),
              SizedBox(height: 26.h),
              PreferenceOptionTile(
                title: 'Quick daily ingredients',
                isSelected: state.primaryGoal == 'daily_ingredients',
                onTap: () => notifier.selectPrimaryGoal('daily_ingredients'),
              ),
              SizedBox(height: 26.h),
              PreferenceOptionTile(
                title: 'Buying in bulk (wholesale)',
                isSelected: state.primaryGoal == 'bulk_wholesale',
                onTap: () => notifier.selectPrimaryGoal('bulk_wholesale'),
              ),
              const Spacer(),
              AppPrimaryButton(
                text: 'Next',
                isLoading: state.isLoading,
                onPressed: state.isPrimaryGoalSelected
                    ? () => notifier.navigateToCookingPreference(context)
                    : null,
                backgroundColor: state.isPrimaryGoalSelected
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
