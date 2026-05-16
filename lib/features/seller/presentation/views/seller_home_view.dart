import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../providers/seller_provider.dart';

class SellerHomeView extends ConsumerWidget {
  const SellerHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerProvider);
    final notifier = ref.read(sellerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability header
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Availability',
                            style: AppTextStyle.bodySm.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          GestureDetector(
                            onTap: () => notifier.toggleAvailability(),
                            child: Row(
                              children: [
                                Text(
                                  state.isAvailable
                                      ? "I'm accepting orders"
                                      : "I'm not accepting orders",
                                  style: AppTextStyle.labelMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(Icons.keyboard_arrow_down,
                                    size: 18.sp, color: AppColors.textDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.pushNamed(RouteNames.notifications),
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.notifications_none,
                            size: 22.sp, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),

              // Availability banner
              if (state.isAvailable)
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  color: AppColors.successBg,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16.sp, color: AppColors.verifiedGreen),
                      SizedBox(width: 8.w),
                      Text(
                        'You are currently available for orders',
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.verifiedGreen,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 16.h),

              // Wallet card
              _buildWalletCard(context, state),

              SizedBox(height: 20.h),

              // Active Tasks
              _buildActiveTasks(),

              SizedBox(height: 20.h),

              // Available Lists
              _buildAvailableLists(),

              SizedBox(height: 20.h),

              // High Demand Areas
              _buildHighDemandAreas(),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, SellerState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.secondary500,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Wallet Balance',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.white.withOpacity(0.7),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.visibility_outlined,
                  size: 16.sp,
                  color: AppColors.white.withOpacity(0.7)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u20A6${_formatNumber(state.walletBalance)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.verifiedGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '+\u20A6${_formatNumber(state.walletGain)}',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.verifiedGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
              // Withdraw button
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 18.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Withdraw',
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.pushNamed(RouteNames.sellerInsights),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Analytics',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.chevron_right,
                      size: 16.sp,
                      color: AppColors.white.withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTasks() {
    final tasks = [
      _TaskData('Tunde Bello', 'Bodija market to IBA Union Street', 7),
      _TaskData('Tunde Bello', 'Bodija market to IBA Union Street', 7),
      _TaskData('Tunde Bello', 'Bodija market to IBA Union Street', 7),
      _TaskData('Tunde Bello', 'Bodija market to IBA Union Street', 7),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Active Tasks',
                    style: AppTextStyle.labelLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flash_on,
                        size: 12.sp, color: AppColors.textDark),
                  ),
                ],
              ),
              Text(
                'See all',
                style: AppTextStyle.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        ...tasks.map((task) => _buildTaskCard(task)),
      ],
    );
  }

  Widget _buildTaskCard(_TaskData task) {
    return Container(
      margin: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.grey50,
            child: Icon(Icons.person, size: 22.sp, color: AppColors.grey400),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.buyerName,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  task.route,
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${task.itemCount} Items',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Items bought',
              style: AppTextStyle.bodySm.copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableLists() {
    final lists = [
      _ListData('Wellens Rufus', 1500, 7, 'Bodija market to IBA Union Street',
          '1 hour to go'),
      _ListData('Wellens Rufus', 1500, 7, 'Bodija market to IBA Union Street',
          '1 hour to go'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Text(
                'Available Lists',
                style: AppTextStyle.labelLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: const BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.list_alt,
                    size: 12.sp, color: AppColors.textDark),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: lists
                .map((l) => Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: _buildListCard(l),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard(_ListData data) {
    return Container(
      width: 180.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor: AppColors.grey50,
                child:
                    Icon(Icons.person, size: 16.sp, color: AppColors.grey400),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  data.buyerName,
                  style: AppTextStyle.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 11.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '\u20A6${_formatNumber(data.amount.toDouble())}',
            style: AppTextStyle.labelMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${data.itemCount} Items',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 11.sp,
            ),
          ),
          Text(
            data.location,
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 10.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            data.timeLeft,
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verifiedGreen,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Accept',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighDemandAreas() {
    final areas = [
      'Oluyole Estate',
      'UI main gate',
      'Akobo',
      'Total Garden',
      'Aare Avenue',
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'High Demand Areas Closeby',
            style: AppTextStyle.labelLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: areas
                .map((area) => Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.grey50),
                      ),
                      child: Text(
                        area,
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000) {
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
    return number.toStringAsFixed(0);
  }
}

class _TaskData {
  final String buyerName;
  final String route;
  final int itemCount;
  const _TaskData(this.buyerName, this.route, this.itemCount);
}

class _ListData {
  final String buyerName;
  final double amount;
  final int itemCount;
  final String location;
  final String timeLeft;
  const _ListData(
      this.buyerName, this.amount, this.itemCount, this.location, this.timeLeft);
}
