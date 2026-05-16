import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../providers/hustle_list_provider.dart';

class HustleListSuccessView extends ConsumerWidget {
  const HustleListSuccessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(hustleListProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: GestureDetector(
                  onTap: () => notifier.navigateToHome(context),
                  child: Icon(Icons.close,
                      size: 24.sp, color: AppColors.textDark),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Success illustration
            Center(
              child: SizedBox(
                width: 180.w,
                height: 180.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background decorative leaves
                    Positioned(
                      left: 10.w,
                      top: 30.h,
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Icon(
                          Icons.eco_outlined,
                          size: 40.sp,
                          color: AppColors.grey50,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10.w,
                      top: 30.h,
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Icon(
                          Icons.eco_outlined,
                          size: 40.sp,
                          color: AppColors.grey50,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20.w,
                      bottom: 20.h,
                      child: Transform.rotate(
                        angle: -0.8,
                        child: Icon(
                          Icons.eco_outlined,
                          size: 32.sp,
                          color: AppColors.grey50,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20.w,
                      bottom: 20.h,
                      child: Transform.rotate(
                        angle: 0.8,
                        child: Icon(
                          Icons.eco_outlined,
                          size: 32.sp,
                          color: AppColors.grey50,
                        ),
                      ),
                    ),
                    // Main checkmark circle
                    Container(
                      width: 120.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary500,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check,
                          size: 64.sp,
                          color: AppColors.primary500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Title
            Text(
              'Your List has been sent!',
              style: AppTextStyle.headingMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'You can find your list in Your list section',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(flex: 3),

            // Go to Home button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: AppPrimaryButton(
                text: 'Goto Home Screen',
                onPressed: () => notifier.navigateToHome(context),
                backgroundColor: AppColors.secondary500,
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
