import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/verification_provider.dart';
import '../widgets/confirmation_bottom_sheet.dart';

class IdCaptureView extends ConsumerWidget {
  const IdCaptureView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(verificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.cameraDark,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new,
                          size: 18.sp,
                          color: AppColors.white,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Back',
                          style: AppTextStyle.labelMd.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Camera preview placeholder (ID card area)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 48.sp,
                          color: AppColors.white.withOpacity(0.5),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Position your ID here',
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Instructions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                children: [
                  Text(
                    'Take a photo of your ID',
                    style: AppTextStyle.headingMd.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Be sure your document shows:',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  _buildBulletPoint('Your address'),
                  SizedBox(height: 6.h),
                  _buildBulletPoint('Your name only'),
                  SizedBox(height: 6.h),
                  _buildBulletPoint('Legible and recent info (past 3 months)'),
                ],
              ),
            ),

            const Spacer(),

            // Camera controls
            Padding(
              padding: EdgeInsets.only(bottom: 40.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shutter button
                  GestureDetector(
                    onTap: () => _onCapture(context, notifier),
                    child: Container(
                      width: 72.w,
                      height: 72.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 58.w,
                          height: 58.h,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 40.w),
                  // Camera switch icon
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '\u2022  ',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          text,
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _onCapture(BuildContext context, VerificationNotifier notifier) async {
    final result = await ConfirmationBottomSheet.show(
      context,
      title: 'Is the ID easy to read?',
      subtitle:
          'Please make sure the text is clear and your entire card is visible.',
    );

    if (result == true && context.mounted) {
      await notifier.uploadId('dummy_path/id_card.jpg');
      if (context.mounted) {
        notifier.navigateToFaceId(context);
      }
    }
  }
}
