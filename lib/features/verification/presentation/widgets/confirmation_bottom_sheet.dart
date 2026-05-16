import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';

class ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const ConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onConfirm,
    required this.onRetake,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmationBottomSheet(
        title: title,
        subtitle: subtitle,
        onConfirm: () => Navigator.of(context).pop(true),
        onRetake: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyle.headingMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          AppPrimaryButton(
            text: 'Yes, looks good',
            onPressed: onConfirm,
            backgroundColor: AppColors.secondary500,
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: onRetake,
            child: Text(
              'Take again',
              style: AppTextStyle.bodyLg.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
