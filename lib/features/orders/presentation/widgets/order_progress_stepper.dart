import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/order_model.dart';

class OrderProgressStepper extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderProgressStepper({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData('Accepted', OrderStatus.accepted),
      _StepData('Shopping', OrderStatus.shopping),
      _StepData(
          currentStatus == OrderStatus.done ? 'Delivered' : 'Delivering',
          OrderStatus.delivering),
      _StepData('Done', OrderStatus.done),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isActive =
                _statusIndex(currentStatus) > stepIndex;
            return Expanded(
              child: Container(
                height: 2.h,
                color: isActive
                    ? AppColors.primary500
                    : AppColors.progressInactive,
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final step = steps[stepIndex];
            final isActive =
                _statusIndex(currentStatus) >= stepIndex;
            final isCurrent =
                _statusIndex(currentStatus) == stepIndex;

            return Column(
              children: [
                Container(
                  width: 28.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary500
                        : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary500
                          : AppColors.progressInactive,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isActive && !isCurrent
                        ? Icon(Icons.check,
                            size: 14.sp, color: AppColors.textDark)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.textDark
                                  : AppColors.textGrey,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  step.label,
                  style: AppTextStyle.bodySm.copyWith(
                    fontSize: 10.sp,
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.textDark
                        : AppColors.textGrey,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  int _statusIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 0;
      case OrderStatus.shopping:
        return 1;
      case OrderStatus.delivering:
        return 2;
      case OrderStatus.done:
        return 3;
      case OrderStatus.cancelled:
      case OrderStatus.pendingAdjustment:
        return 0;
    }
  }
}

class _StepData {
  final String label;
  final OrderStatus status;

  const _StepData(this.label, this.status);
}
