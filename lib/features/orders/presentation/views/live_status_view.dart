import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import '../widgets/cancel_item_dialog.dart';
import '../widgets/order_progress_stepper.dart';

class LiveStatusView extends ConsumerWidget {
  final OrderModel order;

  const LiveStatusView({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for updates
    final state = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);
    final currentOrder =
        state.orders.firstWhere((o) => o.id == order.id, orElse: () => order);

    final isDelivering =
        currentOrder.status == OrderStatus.delivering ||
        currentOrder.status == OrderStatus.done;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20.sp, color: AppColors.textDark),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Status',
                        style: AppTextStyle.headingSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Order ${currentOrder.orderNumber}',
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress stepper
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: OrderProgressStepper(
                  currentStatus: currentOrder.status),
            ),

            SizedBox(height: 8.h),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // Hustler info card
                    _buildHustlerCard(currentOrder),

                    SizedBox(height: 16.h),

                    // Location
                    Divider(height: 1, color: AppColors.grey50),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 18.sp, color: AppColors.textGrey),
                          SizedBox(width: 8.w),
                          Text(
                            currentOrder.location,
                            style: AppTextStyle.bodyMd.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: Icon(Icons.arrow_forward,
                                size: 14.sp, color: AppColors.textGrey),
                          ),
                          Text(
                            currentOrder.deliveryAddress,
                            style: AppTextStyle.bodyMd.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppColors.grey50),

                    // ETA
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18.sp, color: AppColors.textGrey),
                          SizedBox(width: 8.w),
                          Text(
                            'ETA: ${currentOrder.eta}',
                            style: AppTextStyle.bodyMd.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Shopping List header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shopping List',
                          style: AppTextStyle.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${currentOrder.completedItemCount}/${currentOrder.items.length} items',
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Shopping items
                    ...currentOrder.items.map((item) =>
                        _buildShoppingItem(
                            context, item, currentOrder, notifier, isDelivering)),

                    SizedBox(height: 24.h),

                    // Delivery info message when delivering
                    if (currentOrder.status == OrderStatus.delivering ||
                        currentOrder.status == OrderStatus.done)
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16.sp, color: AppColors.textGrey),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'The Seller says the items have been delivered. They are waiting for your confirmation. Please confirm as soon as possible.',
                                style: AppTextStyle.bodySm.copyWith(
                                  color: AppColors.textGrey,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            // Bottom button
            if (currentOrder.status == OrderStatus.delivering)
              Container(
                padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
                color: Colors.white,
                child: AppPrimaryButton(
                  text: 'Mark as Delivered',
                  onPressed: () {
                    notifier.markAsDelivered(currentOrder.id);
                    notifier.navigateToRateExperience(context, currentOrder);
                  },
                  backgroundColor: AppColors.secondary500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHustlerCard(OrderModel order) {
    return Row(
      children: [
        // Hustler avatar
        CircleAvatar(
          radius: 24.r,
          backgroundColor: AppColors.grey50,
          child: Icon(Icons.person, size: 28.sp, color: AppColors.grey400),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.hustlerName,
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                order.hustlerRole,
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        // Chat button
        Container(
          width: 44.w,
          height: 44.h,
          decoration: const BoxDecoration(
            color: AppColors.secondary500,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble_outline,
              size: 20.sp, color: AppColors.white),
        ),
      ],
    );
  }

  Widget _buildShoppingItem(
    BuildContext context,
    OrderItemModel item,
    OrderModel order,
    OrdersNotifier notifier,
    bool isDelivering,
  ) {
    final isCompleted = item.isCompleted;
    final isCancelled = item.isCancelled;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.successBg.withOpacity(0.5)
            : AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: isCompleted
            ? Border.all(color: AppColors.successBg)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox
              Container(
                width: 28.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.verifiedGreen
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isCompleted
                      ? null
                      : Border.all(color: AppColors.grey50, width: 2),
                ),
                child: isCompleted
                    ? Icon(Icons.check,
                        size: 16.sp, color: AppColors.white)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyle.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${item.quantity} \u2022 \u20A6${item.price.toStringAsFixed(0)}',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 12.sp,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action links (only when not completed and not delivering)
          if (!isCompleted && !isCancelled && !isDelivering) ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(left: 40.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: Suggest alternative
                    },
                    child: Text(
                      'Suggest Alternative',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.verifiedGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      '\u2022',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result =
                          await CancelItemDialog.show(context);
                      if (result == true) {
                        notifier.cancelItem(order.id, item.id);
                      }
                    },
                    child: Text(
                      'Cancel Item',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.logOutRed,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Show suggest alternative greyed when completed
          if (isCompleted) ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(left: 40.w),
              child: Text(
                'Suggest Alternative',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
