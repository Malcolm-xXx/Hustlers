import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_header.dart';
import '../providers/sign_up_provider.dart';

class IdVerificationView extends ConsumerWidget {
  const IdVerificationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 26.h),

            const AuthHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 30.h),
                    Text(
                      'ID Verification',
                      style: AppTextStyle.headingLg,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    AppTextField(
                      label: 'National Identification Number (NIN)',
                      hintText: 'Enter your NIN',
                      keyboardType: TextInputType.number,
                      onChanged: notifier.setNin,
                      textInputAction: TextInputAction.done,
                    ),

                    const Spacer(),

                    AppPrimaryButton(
                      text: 'Next',
                      onPressed: state.isNinValid
                          ? () => notifier.navigateToFingerprint(context)
                          : null,
                      backgroundColor: state.isNinValid
                          ? AppColors.secondary400
                          : AppColors.buttonDisabled,
                      disabledBackgroundColor: AppColors.buttonDisabled,
                      disabledForegroundColor: AppColors.white,
                    ),
                    const SizedBox(height: 8),

                    AppTextButton(
                      textStyle: AppTextStyle.bodyLg,
                      text: 'Skip',
                      onPressed: () => notifier.navigateToFingerprint(context),
                      foregroundColor: AppColors.secondary500,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
