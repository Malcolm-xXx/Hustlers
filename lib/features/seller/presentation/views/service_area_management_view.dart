import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/insights_model.dart';
import '../providers/insights_provider.dart';

class ServiceAreaManagementView extends ConsumerWidget {
  const ServiceAreaManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceAreaProvider);
    final notifier = ref.read(serviceAreaProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20.sp, color: AppColors.textDark),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Service Area Management',
                    style: AppTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Status badges
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  // Currently Serving
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.secondary500,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on,
                            size: 14.sp, color: AppColors.primary500),
                        SizedBox(width: 4.w),
                        Text(
                          'Currently Serving',
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${state.activeAreas.length} Areas',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Nearest Others
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'Nearest ${state.availableAreas.length} Others',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  // Active Coverage
                  if (state.activeAreas.isNotEmpty) ...[
                    Text(
                      'Active Coverage',
                      style: AppTextStyle.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...state.activeAreas.map((area) =>
                        _buildActiveAreaItem(area, notifier)),
                    SizedBox(height: 20.h),
                  ],

                  // Available Areas
                  Text(
                    'Available Areas',
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ...state.availableAreas.map((area) =>
                      _buildAvailableAreaItem(area, notifier)),
                  SizedBox(height: 80.h),
                ],
              ),
            ),

            // Save button
            if (state.selectedCount > 0)
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.grey50),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      notifier.saveCoverageAreas();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary500,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Coverage Areas (${state.selectedCount})',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAreaItem(
      ServiceAreaModel area, ServiceAreaNotifier notifier) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Green active indicator
          Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: AppColors.verifiedGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              area.name,
              style: AppTextStyle.labelMd.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => notifier.removeActiveArea(area.id),
            child: Text(
              'Remove',
              style: AppTextStyle.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.logOutRed,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableAreaItem(
      ServiceAreaModel area, ServiceAreaNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.toggleAreaSelection(area.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: area.isSelected
              ? AppColors.primary100
              : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: area.isSelected
              ? Border.all(color: AppColors.primary500)
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Checkbox
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    color: area.isSelected
                        ? AppColors.primary500
                        : Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                    border: area.isSelected
                        ? null
                        : Border.all(color: AppColors.grey50, width: 2),
                  ),
                  child: area.isSelected
                      ? Icon(Icons.check,
                          size: 14.sp, color: AppColors.textDark)
                      : null,
                ),
                SizedBox(width: 12.w),

                // Name
                Expanded(
                  child: Text(
                    area.name,
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ),

                // Avg earning
                if (area.avgEarning != null)
                  Text(
                    '\u20A6${_formatNumber(area.avgEarning!)}',
                    style: AppTextStyle.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            // Demand bar
            Padding(
              padding: EdgeInsets.only(left: 34.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: area.demand,
                  backgroundColor: AppColors.grey50,
                  color: AppColors.primary500,
                  minHeight: 6.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    final formatted = number.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(formatted[i]);
    }
    return result.toString();
  }
}
