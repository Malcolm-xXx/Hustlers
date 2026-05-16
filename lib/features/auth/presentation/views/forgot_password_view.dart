import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_header.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/forgot_password_provider.dart';

class ForgotPasswordView extends ConsumerWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forgotPasswordProvider);
    final notifier = ref.read(forgotPasswordProvider.notifier);

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: const AuthHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 24.h),
                    Text(
                      'Forgot Password',
                      style: AppTextStyle.headingLg.copyWith(height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 7.h),
                    Text(
                      'Enter your email or Phone to reset your password',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.grey400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),

                    AppTextField(
                      label: 'Email or Phone',
                      hintText: 'Enter Your Email',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: notifier.setEmail,
                      textInputAction: TextInputAction.done,
                    ),

                    SizedBox(height: 30.h),

                    AppPrimaryButton(
                      text: 'Send Code',
                      onPressed: state.canSendCode
                          ? () => notifier.sendCode(context)
                          : null,
                      backgroundColor: state.canSendCode
                          ? AppColors.secondary400
                          : AppColors.buttonDisabled,
                      disabledBackgroundColor: AppColors.buttonDisabled,
                      disabledForegroundColor: AppColors.white,
                    ),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
