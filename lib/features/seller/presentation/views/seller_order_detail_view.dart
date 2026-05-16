import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/seller_order_model.dart';
import '../providers/seller_orders_provider.dart';

class SellerOrderDetailView extends ConsumerWidget {
  final String orderId;

  const SellerOrderDetailView({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerOrdersProvider);
    final notifier = ref.read(sellerOrdersProvider.notifier);
    final order = state.orders.where((o) => o.id == orderId).firstOrNull;

    if (order == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Order not found',
              style: AppTextStyle.bodyMd),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context, order),

                    SizedBox(height: 16.h),

                    // Progress stepper
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _OrderProgressStepper(
                          currentStatus: order.status),
                    ),

                    SizedBox(height: 24.h),

                    // Buyer card
                    _buildBuyerCard(order),

                    SizedBox(height: 20.h),

                    // Set Delivery Time
                    _buildDeliveryTimeSection(order, notifier),

                    // Customer notified banner
                    if (order.deliveryTimeMinutes != null) ...[
                      SizedBox(height: 12.h),
                      _buildCustomerNotifiedBanner(order),
                    ],

                    SizedBox(height: 20.h),

                    // Shopping List
                    _buildShoppingList(order, notifier),

                    SizedBox(height: 24.h),

                    // Action button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _buildActionButton(order, notifier),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Bottom: Order Total + Commission
            _buildOrderSummary(order),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SellerOrderModel order) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
                'Order ${order.orderNumber}',
                style: AppTextStyle.headingSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Order Details & Management',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerCard(SellerOrderModel order) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.grey50,
            backgroundImage: order.buyerAvatarUrl.isNotEmpty
                ? NetworkImage(order.buyerAvatarUrl)
                : null,
            child: order.buyerAvatarUrl.isEmpty
                ? Icon(Icons.person,
                    size: 28.sp, color: AppColors.grey400)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.buyerName,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Buyer',
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
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primary500,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline,
                size: 18.sp, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeSection(
      SellerOrderModel order, SellerOrdersNotifier notifier) {
    final timeOptions = [
      {'label': '15 mins', 'minutes': 15},
      {'label': '30 mins', 'minutes': 30},
      {'label': '1 hour', 'minutes': 60},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 18.sp, color: AppColors.textDark),
              SizedBox(width: 8.w),
              Text(
                'Set Delivery Time',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: timeOptions.map((option) {
              final minutes = option['minutes'] as int;
              final label = option['label'] as String;
              final isSelected = order.deliveryTimeMinutes == minutes;

              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: GestureDetector(
                  onTap: () => notifier.setDeliveryTime(orderId, minutes),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 18.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary500
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary500
                            : AppColors.grey50,
                      ),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyle.bodySm.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textDark,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerNotifiedBanner(SellerOrderModel order) {
    final etaText = order.deliveryTimeMinutes == 60
        ? 'ETA 60 minutes'
        : 'ETA ${order.deliveryTimeMinutes} minutes';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.check,
                size: 16.sp, color: AppColors.verifiedGreen),
            SizedBox(width: 8.w),
            Text(
              'Customer notified: $etaText',
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.verifiedGreen,
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingList(
      SellerOrderModel order, SellerOrdersNotifier notifier) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shopping List',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${order.checkedCount}/${order.items.length} items',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Items
          ...order.items.map((item) =>
              _buildShoppingItem(item, order, notifier)),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(
    SellerOrderItem item,
    SellerOrderModel order,
    SellerOrdersNotifier notifier,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: item.isChecked
              ? AppColors.verifiedGreen.withOpacity(0.3)
              : AppColors.grey50,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => notifier.toggleItemChecked(orderId, item.id),
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: item.isChecked
                    ? AppColors.verifiedGreen
                    : Colors.white,
                shape: BoxShape.circle,
                border: item.isChecked
                    ? null
                    : Border.all(
                        color: AppColors.grey50,
                        width: 2,
                      ),
              ),
              child: item.isChecked
                  ? Icon(Icons.check,
                      size: 16.sp, color: AppColors.white)
                  : null,
            ),
          ),
          SizedBox(width: 12.w),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: item.isChecked
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.textGrey,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${item.quantityUnit} \u2022 \u20A6${_formatNumber(item.price)}',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                // Action links
                Row(
                  children: [
                    GestureDetector(
                      onTap: item.isChecked ? null : () {},
                      child: Text(
                        'Suggest Alternative',
                        style: AppTextStyle.bodySm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: item.isChecked
                              ? AppColors.textGrey
                                  .withOpacity(0.4)
                              : AppColors.verifiedGreen,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    if (!item.isChecked) ...[
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          '\u2022',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Adjust Price',
                          style: AppTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFF9800),
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      SellerOrderModel order, SellerOrdersNotifier notifier) {
    String buttonText;
    switch (order.status) {
      case SellerOrderStatus.accepted:
        buttonText = 'Start Shopping';
      case SellerOrderStatus.shopping:
        buttonText = 'Start Shopping';
      case SellerOrderStatus.delivering:
        // Check if all items done
        if (order.checkedCount == order.items.length) {
          buttonText = 'Mark as Delivered';
        } else {
          buttonText = 'On the way';
        }
      case SellerOrderStatus.done:
        buttonText = 'Completed';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: order.status == SellerOrderStatus.done
            ? null
            : () => notifier.advanceStatus(orderId),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary500,
          disabledBackgroundColor: AppColors.grey50,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.textGrey,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.r),
          ),
          elevation: 0,
        ),
        child: Text(
          buttonText,
          style: AppTextStyle.bodyMd.copyWith(
            color: order.status == SellerOrderStatus.done
                ? AppColors.textGrey
                : AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(SellerOrderModel order) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.grey50, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total:',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                '\u20A6${_formatNumber(order.orderTotal)}',
                style: AppTextStyle.headingSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Commission:',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                '\u20A6${_formatNumber(order.commission)}',
                style: AppTextStyle.headingSm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.verifiedGreen,
                ),
              ),
            ],
          ),
        ],
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

// ─── PROGRESS STEPPER WIDGET ───

class _OrderProgressStepper extends StatelessWidget {
  final SellerOrderStatus currentStatus;

  const _OrderProgressStepper({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final currentStep = currentStatus.stepIndex;
    final labels = ['Accepted', 'Shopping', 'Delivering', 'Done'];

    return Row(
      children: List.generate(7, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          final isCompleted = stepBefore < currentStep;
          return Expanded(
            child: Container(
              height: 2.5.h,
              color: isCompleted
                  ? AppColors.verifiedGreen
                  : AppColors.grey50,
            ),
          );
        }

        // Step circle
        final step = index ~/ 2;
        final isCompleted = step < currentStep;
        final isCurrent = step == currentStep;

        return Column(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.verifiedGreen
                    : isCurrent
                        ? AppColors.primary500
                        : AppColors.grey50,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(
                        color: AppColors.primary500, width: 2)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check,
                        size: 18.sp, color: AppColors.white)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppColors.textDark
                              : AppColors.textGrey,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              labels[step],
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.sp,
                fontWeight: isCurrent || isCompleted
                    ? FontWeight.w600
                    : FontWeight.w400,
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
