import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../providers/verification_provider.dart';
import '../widgets/id_type_option_tile.dart';
import '../widgets/verification_progress_bar.dart';
import '../widgets/verification_toast_banner.dart';

class SelectIdTypeView extends ConsumerWidget {
  const SelectIdTypeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Progress bar
            const VerificationProgressBar(currentStep: 0),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32.h),

                    Text(
                      'Select your ID type',
                      style: AppTextStyle.headingLg.copyWith(
                        fontSize: 22.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'We\'ll take a pictures of your ID. What type of ID do you want to use?',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // ID type options
                    IdTypeOptionTile(
                      title: 'ID Card',
                      onTap: () {
                        notifier.selectIdType(IdType.id_card);
                        context.pushNamed(RouteNames.idCapture);
                      },
                    ),
                    Divider(height: 1, color: AppColors.grey50),
                    IdTypeOptionTile(
                      title: 'NIN Card/Slip',
                      onTap: () {
                        notifier.selectIdType(IdType.nin);
                        context.pushNamed(RouteNames.idCapture);
                      },
                    ),
                    Divider(height: 1, color: AppColors.grey50),
                    IdTypeOptionTile(
                      title: 'Driver\u2019s License',
                      subtitle: 'Recommended',
                      onTap: () {
                        notifier.selectIdType(IdType.drivers_license);
                        context.pushNamed(RouteNames.idCapture);
                      },
                    ),
                    Divider(height: 1, color: AppColors.grey50),
                    IdTypeOptionTile(
                      title: 'Passport',
                      onTap: () {
                        notifier.selectIdType(IdType.passport);
                        context.pushNamed(RouteNames.idCapture);
                      },
                    ),

                    SizedBox(height: 32.h),

                    // Privacy notice
                    Text(
                      'Your photo ID and actions captured during the ID verification process may constitute biometric data. Please see our Privacy Policy for more information about how we store and use your biometric data.',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Why verify info card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.infoCardBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why do I need to verify?',
                            style: AppTextStyle.labelMd.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildInfoItem('Upload products for sale'),
                          SizedBox(height: 8.h),
                          _buildInfoItem('Build trust with buyers'),
                          SizedBox(height: 8.h),
                          _buildInfoItem('Get paid for your products'),
                        ],
                      ),
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

  Widget _buildInfoItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 16.sp,
          color: AppColors.primary500,
        ),
        SizedBox(width: 10.w),
        Text(
          text,
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}
