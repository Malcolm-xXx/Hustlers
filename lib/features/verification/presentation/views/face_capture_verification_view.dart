import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/verification_provider.dart';
import '../widgets/confirmation_bottom_sheet.dart';

class FaceCaptureVerificationView extends ConsumerWidget {
  const FaceCaptureVerificationView({super.key});

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

            // Camera preview placeholder (face area)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.face,
                          size: 64.sp,
                          color: AppColors.white.withOpacity(0.5),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Camera Preview',
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

            SizedBox(height: 24.h),

            // Instructions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                children: [
                  Text(
                    'Align Your face in the middle',
                    style: AppTextStyle.headingMd.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Make sure your face is inside the box and capture a photo',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

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

  void _onCapture(BuildContext context, VerificationNotifier notifier) async {
    final result = await ConfirmationBottomSheet.show(
      context,
      title: 'Is the photo clear enough?',
      subtitle:
          'Please make sure the photo is clear and all parts of your face are visible',
    );

    if (result == true && context.mounted) {
      await notifier.uploadFaceScan('dummy_path/face.jpg');
      if (context.mounted) {
        notifier.navigateToVerificationComplete(context);
      }
    }
  }
}
