import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_header.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/social_login_row.dart';
import '../providers/google_sign_in_provider.dart';
import '../providers/sign_up_provider.dart';

class SignUpView extends ConsumerWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signUpProvider);
    final notifier = ref.read(signUpProvider.notifier);
    final googleState = ref.watch(googleSignInProvider);

    ref.listen(googleSignInProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return LoadingOverlay(
      isLoading: state.isLoading || googleState.isLoading,
      child: Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
           // SizedBox(height: 26.h,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const AuthHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Create an Account',
                      style: AppTextStyle.headingLg.copyWith(
                        height: 1.4

                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 7.h),

                    Text(
                      'Enter your details below ',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.grey400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    AppTextField(
                      label: 'Name',
                      hintText: 'Enter your name',
                      onChanged: notifier.setName,
                      textInputAction: TextInputAction.next,
                      errorText: state.nameError,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Phone Number',
                      hintText: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                      onChanged: notifier.setPhone,
                      textInputAction: TextInputAction.next,
                      errorText: state.phoneError,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              AppAssets.icNigeriaFlag,
                              width: 24,
                              height: 18,
                            ),
                            const SizedBox(width: 4),
                            SvgPicture.asset(
                              AppAssets.icChevronDown,
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(AppColors.dropdownColor, BlendMode.srcIn),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Email',
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: notifier.setEmail,
                      textInputAction: TextInputAction.next,
                      errorText: state.emailError,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Password',
                      hintText: 'Enter your password',
                      obscureText: state.obscurePassword,
                      onChanged: notifier.setPassword,
                      textInputAction: TextInputAction.done,
                      errorText: state.passwordError,
                      suffixIcon: GestureDetector(
                        onTap: notifier.toggleObscurePassword,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            state.obscurePassword
                                ? AppAssets.icEyeClosed
                                : AppAssets.icEyeOpen,
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    AppPrimaryButton(
                      text: 'Next',
                      onPressed: state.isFormValid
                          ? () => notifier.submitSignUp(context)
                          : null,
                      backgroundColor: state.isFormValid
                          ? AppColors.secondary400
                          : AppColors.dividerColor.withOpacity(0.5),
                      disabledBackgroundColor: AppColors.buttonDisabled,
                      disabledForegroundColor: AppColors.white,
                      isLoading: state.isLoading,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(

                              color: AppColors.dividerColor.withOpacity(0.34),
                            thickness: 1.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or continue with',
                            style: AppTextStyle.bodyMd.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.dividerColor.withOpacity(0.34),
                            thickness: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SocialLoginRow(
                      onGoogleTap: () => ref
                          .read(googleSignInProvider.notifier)
                          .signIn(context),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyle.bodyMd.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.goNamed(RouteNames.signIn);
                          },
                          child: Text(
                            'Sign In',
                            style: AppTextStyle.bodyMd.copyWith(
                              color: AppColors.primary500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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
