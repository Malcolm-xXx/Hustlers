import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../../../../core/widgets/auth_header.dart';
import '../providers/sign_up_provider.dart';

class FaceCaptureView extends ConsumerWidget {
  const FaceCaptureView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(signUpProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AuthHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Create an Account',
                      style: AppTextStyle.headingLg,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Position your face in the frame.\nEnsure proper lighting.',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary500,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 64,
                                color: AppColors.textGrey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Camera Preview',
                                style: AppTextStyle.bodyMd.copyWith(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    AppPrimaryButton(
                      text: 'Done',
                      onPressed: () => notifier.navigateToOtp(context),
                      backgroundColor: AppColors.secondary400,
                    ),
                    const SizedBox(height: 8),

                    AppTextButton(
                      textStyle: AppTextStyle.bodyLg,

                      text: 'Skip',
                      onPressed: () => notifier.navigateToHome(context),
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
