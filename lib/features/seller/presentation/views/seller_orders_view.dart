import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../data/models/seller_order_model.dart';
import '../providers/seller_orders_provider.dart';

class SellerOrdersView extends ConsumerWidget {
  const SellerOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20.sp, color: AppColors.textDark),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'My Orders',
                    style: AppTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Delivery filter
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 14.sp, color: AppColors.textDark),
                        SizedBox(width: 4.w),
                        Text(
                          'Delivery',
                          style: AppTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Active filter chip
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Active',
                          style: AppTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppColors.textDark,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${state.activeCount}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Order list
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: state.activeOrders.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final order = state.activeOrders[index];
                  return _SellerOrderCard(order: order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final SellerOrderModel order;

  const _SellerOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        RouteNames.sellerOrderDetail,
        extra: order.id,
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order number + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${order.orderNumber}',
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: order.status.badgeBgColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    order.status.label,
                    style: AppTextStyle.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: order.status.badgeColor,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Buyer info
            Row(
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: AppColors.grey50,
                  backgroundImage: order.buyerAvatarUrl.isNotEmpty
                      ? NetworkImage(order.buyerAvatarUrl)
                      : null,
                  child: order.buyerAvatarUrl.isEmpty
                      ? Icon(Icons.person,
                          size: 16.sp, color: AppColors.grey400)
                      : null,
                ),
                SizedBox(width: 8.w),
                Text(
                  order.buyerName,
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),

            // Route
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14.sp, color: AppColors.textGrey),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    order.route,
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 11.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Progress stepper dots
            _buildProgressDots(),

            SizedBox(height: 14.h),

            // Action button
            if (_actionText != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pushNamed(
                    RouteNames.sellerOrderDetail,
                    extra: order.id,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary500,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _actionText!,
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // View Details link for delivering/shopping orders without main button
            if (_actionText == null) ...[
              Center(
                child: GestureDetector(
                  onTap: () => context.pushNamed(
                    RouteNames.sellerOrderDetail,
                    extra: order.id,
                  ),
                  child: Text(
                    'View Details',
                    style: AppTextStyle.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? get _actionText {
    switch (order.status) {
      case SellerOrderStatus.accepted:
        return 'Start Shopping';
      case SellerOrderStatus.delivering:
        return 'Mark as Delivered';
      case SellerOrderStatus.shopping:
      case SellerOrderStatus.done:
        return null;
    }
  }

  Widget _buildProgressDots() {
    final currentStep = order.status.stepIndex;
    const totalSteps = 4;
    final labels = ['Accepted', 'Shopping', 'Delivering', 'Done'];

    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          final isCompleted = stepBefore < currentStep;
          return Expanded(
            child: Container(
              height: 2.h,
              color: isCompleted
                  ? AppColors.verifiedGreen
                  : AppColors.grey50,
            ),
          );
        }

        // Step dot
        final step = index ~/ 2;
        final isCompleted = step < currentStep;
        final isCurrent = step == currentStep;

        return Column(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.verifiedGreen
                    : isCurrent
                        ? AppColors.primary500
                        : AppColors.grey50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check,
                        size: 14.sp, color: AppColors.white)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppColors.textDark
                              : AppColors.textGrey,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              labels[step],
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 8.sp,
                fontWeight:
                    isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCompleted || isCurrent
                    ? AppColors.textDark
                    : AppColors.textGrey,
              ),
            ),
          ],
        );
      }),
    );
  }
}
