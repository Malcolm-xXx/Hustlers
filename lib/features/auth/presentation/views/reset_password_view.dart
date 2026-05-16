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

class ResetPasswordView extends ConsumerWidget {
  const ResetPasswordView({super.key});

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
                      'Reset Password',
                      style: AppTextStyle.headingLg.copyWith(height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 7.h),
                    Text(
                      'Enter a new password',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.grey400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),

                    // New password
                    AppTextField(
                      label: 'Enter new password',
                      hintText: 'Enter Your New Password',
                      obscureText: !state.isPasswordVisible,
                      onChanged: notifier.setNewPassword,
                      textInputAction: TextInputAction.next,
                      suffixIcon: GestureDetector(
                        onTap: notifier.togglePasswordVisibility,
                        child: Icon(
                          state.isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.grey400,
                          size: 22.sp,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Confirm password
                    AppTextField(
                      label: 'Confirm Password',
                      hintText: 'Confirm Your Password',
                      obscureText: !state.isConfirmVisible,
                      onChanged: notifier.setConfirmPassword,
                      textInputAction: TextInputAction.done,
                      suffixIcon: GestureDetector(
                        onTap: notifier.toggleConfirmVisibility,
                        child: Icon(
                          state.isConfirmVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.grey400,
                          size: 22.sp,
                        ),
                      ),
                    ),

                    SizedBox(height: 30.h),

                    AppPrimaryButton(
                      text: 'Reset Password',
                      isLoading: state.isLoading,
                      onPressed: state.canResetPassword
                          ? () => notifier.resetPassword(context)
                          : null,
                      backgroundColor: state.canResetPassword
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
