import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../providers/verification_provider.dart';
import '../widgets/verification_progress_bar.dart';
import '../widgets/verification_toast_banner.dart';

class FaceIdView extends ConsumerWidget {
  const FaceIdView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Banner
            if (state.banner != null)
              VerificationToastBanner(
                banner: state.banner!,
                onDismiss: notifier.dismissBanner,
              ),

            // App bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Get Verified',
                    style: AppTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar - step 2
            const VerificationProgressBar(currentStep: 1),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32.h),
                    Text(
                      'Face ID Verification',
                      style: AppTextStyle.headingLg.copyWith(
                        fontSize: 22.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Verify your identity with Face ID',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),

                    const Spacer(),

                    // Face illustration with concentric circles
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 260.w,
                            height: 260.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary100,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 200.w,
                            height: 200.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary200,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 140.w,
                            height: 140.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SvgPicture.asset(
                            AppAssets.icFaceId,
                            width: 64.w,
                            height: 64.h,
                            colorFilter: const ColorFilter.mode(
                              AppColors.secondary500,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Privacy notice
                    Text(
                      'Your photo and actions captured during the verification process may constitute biometric data. Please see our Privacy Policy for more information about how we store and use your biometric data.',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Scan button
                    AppPrimaryButton(
                      text: 'Scan my face',
                      onPressed: () => notifier.navigateToFaceCapture(context),
                      backgroundColor: AppColors.secondary500,
                    ),

                    SizedBox(height: 32.h),
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
