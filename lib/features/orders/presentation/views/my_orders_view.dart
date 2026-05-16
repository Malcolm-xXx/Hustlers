import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

class MyOrdersView extends ConsumerWidget {
  const MyOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  Text(
                    'My Orders',
                    style: AppTextStyle.headingMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Orders list
            Expanded(
              child: state.orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.all(20.w),
                      itemCount: state.orders.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final order = state.orders[index];
                        return _buildOrderCard(
                            context, order, notifier);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80.sp,
              color: AppColors.grey400.withOpacity(0.4),
            ),
            SizedBox(height: 20.h),
            Text(
              'No Orders Yet',
              style: AppTextStyle.headingSm.copyWith(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your order history will appear here',
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, OrderModel order, OrdersNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.navigateToLiveStatus(context, order),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 1),
              blurRadius: 4,
              color: AppColors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${order.orderNumber}',
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            SizedBox(height: 10.h),

            // Hustler info
            Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: AppColors.grey50,
                  child: Icon(Icons.person,
                      size: 18.sp, color: AppColors.grey400),
                ),
                SizedBox(width: 8.w),
                Text(
                  order.hustlerName,
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Items summary
            Text(
              '${order.items.length} items \u2022 \u20A6${order.total.toStringAsFixed(0)}',
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.textGrey,
              ),
            ),

            SizedBox(height: 8.h),

            // Location
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14.sp, color: AppColors.textGrey),
                SizedBox(width: 4.w),
                Text(
                  '${order.location} \u2192 ${order.deliveryAddress}',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.pending:
        bgColor = AppColors.grey50;
        textColor = AppColors.textGrey;
        label = 'Pending';
      case OrderStatus.accepted:
        bgColor = AppColors.primary100;
        textColor = AppColors.primary600;
        label = 'Accepted';
      case OrderStatus.shopping:
        bgColor = AppColors.primary100;
        textColor = AppColors.primary600;
        label = 'Shopping';
      case OrderStatus.delivering:
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        label = 'Delivering';
      case OrderStatus.done:
        bgColor = AppColors.successBg;
        textColor = AppColors.verifiedGreen;
        label = 'Done';
      case OrderStatus.cancelled:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = 'Cancelled';
      case OrderStatus.pendingAdjustment:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = 'Adjustment';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: AppTextStyle.bodySm.copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
