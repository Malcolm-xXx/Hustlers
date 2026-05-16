import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hustlers/core/constants/app_assets.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/auth_header.dart';
import '../../../../core/widgets/role_selection_card.dart';
import '../providers/sign_up_provider.dart';

class RoleSelectionView extends ConsumerWidget {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              AuthHeader(
                onBack: () {
                  try {
                    context.pop();
                  } catch (e) {
                    context.goNamed(RouteNames.onboarding);
                  }
                }
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Sign Up as',
                      style: AppTextStyle.headingLg.copyWith(
                        fontSize: 26.sp
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a role , you can switch roles anytime in settings',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.fieldBorderInactive,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    RoleSelectionCard(
                      title: 'Seller',
                      isSelected: state.selectedRole == 'seller',
                      icon: AppAssets.seller,
                      onTap: () => notifier.selectRole('seller'),
                    ),
                    const SizedBox(height: 16),

                    RoleSelectionCard(
                      title: 'Buyer',
                      isSelected: state.selectedRole == 'buyer',
                      icon: AppAssets.buyer,
                      onTap: () => notifier.selectRole('buyer'),
                    ),

                    SizedBox(height: 73.h,),

                    AppPrimaryButton(
                      text: 'Continue',
                      onPressed: state.isRoleSelected
                          ? () => notifier.navigateToSignUp(context)
                          : null,
                      backgroundColor: state.isRoleSelected
                          ? AppColors.secondary500
                          : AppColors.buttonDisabled,
                      disabledBackgroundColor: AppColors.buttonDisabled,
                      disabledForegroundColor: AppColors.white,
                      borderRadius: 26.r,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
