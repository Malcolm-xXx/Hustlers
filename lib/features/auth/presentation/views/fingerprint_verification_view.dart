import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../../../../core/widgets/auth_header.dart';
import '../providers/sign_up_provider.dart';

class FingerprintVerificationView extends ConsumerStatefulWidget {
  const FingerprintVerificationView({super.key});

  @override
  ConsumerState<FingerprintVerificationView> createState() =>
      _FingerprintVerificationViewState();
}

class _FingerprintVerificationViewState
    extends ConsumerState<FingerprintVerificationView> {
  bool _fingerprintScanned = false;

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(height: 40),
                    Text(
                      'Fingerprint Verification',
                      style: AppTextStyle.headingLg,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add a fingerprint to make your\naccount more secure',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _fingerprintScanned = !_fingerprintScanned;
                        });
                      },
                      child: SvgPicture.asset(
                        AppAssets.icFingerprint,
                        //width: 120,
                        //height: 120,
                        colorFilter: ColorFilter.mode(
                          _fingerprintScanned
                              ? AppColors.primary500
                              : AppColors.textGrey,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const Spacer(),

                    Text(
                      'Please put your finger on the fingerprint scanner to get started',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    AppPrimaryButton(
                      text: 'Next',
                      onPressed: _fingerprintScanned
                          ? () => notifier.navigateToFaceId(context)
                          : null,
                      backgroundColor: _fingerprintScanned
                          ? AppColors.secondary400
                          : AppColors.buttonDisabled,
                      disabledBackgroundColor: AppColors.buttonDisabled,
                      disabledForegroundColor: AppColors.white,
                    ),
                    const SizedBox(height: 8),

                    AppTextButton(
                      textStyle: AppTextStyle.bodyLg,

                      text: 'Skip',
                      onPressed: () => notifier.navigateToFaceId(context),
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
