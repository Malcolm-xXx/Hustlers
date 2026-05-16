import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/auth_header.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/otp_input_field.dart';
import '../providers/forgot_password_provider.dart';
import '../providers/otp_provider.dart';

enum OtpSource { signUp, forgotPassword }

class OtpVerificationView extends ConsumerWidget {
  final OtpSource source;

  const OtpVerificationView({super.key, this.source = OtpSource.signUp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(otpProvider);
    final notifier = ref.read(otpProvider.notifier);
    final forgotState = ref.watch(forgotPasswordProvider);

    final isLoading = source == OtpSource.forgotPassword
        ? forgotState.isLoading
        : state.isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: const AuthHeader(),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    Text(
                      'OTP Verification',
                      style: AppTextStyle.headingLg,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Enter the code sent to your email or phone',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),

                    OtpInputField(
                      onChanged: notifier.setOtp,
                      onCompleted: (value) => notifier.setOtp(value),
                    ),
                    SizedBox(height: 40.h),

                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                        children: [
                          TextSpan(
                            text: "Didn't get a code? ",
                            style: AppTextStyle.bodySm.copyWith(
                              color: AppColors.grey900,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                            ),
                          ),
                          TextSpan(
                            text: "Resend Code",
                            style: AppTextStyle.bodyLg.copyWith(
                              color: AppColors.grey400,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _canResend(state, forgotState)
                                  ? () => _onResend(ref)
                                  : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),

                    AppPrimaryButton(
                      text: 'Submit',
                      onPressed: state.isOtpComplete && !isLoading
                          ? () => _onVerify(context, ref)
                          : null,
                      backgroundColor: state.isOtpComplete
                          ? AppColors.darkButton
                          : AppColors.buttonDisabled,
                      disabledBackgroundColor: AppColors.buttonDisabled,
                      disabledForegroundColor: AppColors.white,
                      isLoading: isLoading,
                    ),
                    SizedBox(height: 24.h),
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

  bool _canResend(OtpState otpState, ForgotPasswordState forgotState) {
    return source == OtpSource.forgotPassword
        ? forgotState.canResend
        : otpState.canResend;
  }

  void _onResend(WidgetRef ref) {
    if (source == OtpSource.forgotPassword) {
      ref.read(forgotPasswordProvider.notifier).resendOtp();
    } else {
      ref.read(otpProvider.notifier).resendOtp();
    }
  }

  void _onVerify(BuildContext context, WidgetRef ref) {
    if (source == OtpSource.forgotPassword) {
      final otp = ref.read(otpProvider).otp;
      ref.read(forgotPasswordProvider.notifier).setOtp(otp);
      ref.read(forgotPasswordProvider.notifier).verifyOtp(context);
    } else {
      ref.read(otpProvider.notifier).verifyOtp(context);
    }
  }
}
