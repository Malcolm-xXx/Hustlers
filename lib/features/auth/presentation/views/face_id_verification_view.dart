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

class FaceIdVerificationView extends ConsumerWidget {
  const FaceIdVerificationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      'Face ID Verification',
                      style: AppTextStyle.headingLg,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add a face recognition to make your\naccount more secure',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 260.w,
                          height: 260.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary100,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 211.w,
                          height: 211.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary200,

                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 145.w,
                          height: 145.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary500,

                            shape: BoxShape.circle,
                          ),
                        ),
                        SvgPicture.asset(
                          AppAssets.icFaceId,
                          colorFilter: const ColorFilter.mode(
                            AppColors.secondary500,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    AppPrimaryButton(
                      text: 'Scan',
                      onPressed: () =>
                          notifier.navigateToFaceCapture(context),
                      backgroundColor: AppColors.secondary400,
                    ),
                    const SizedBox(height: 8),

                    AppTextButton(
                      textStyle: AppTextStyle.bodyLg,

                      text: 'Skip',
                      onPressed: () =>
                          notifier.navigateToFaceCapture(context),
                      //foregroundColor: AppColors.textGrey,
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
