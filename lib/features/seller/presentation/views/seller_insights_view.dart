import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../data/models/insights_model.dart';
import '../providers/insights_provider.dart';

class SellerInsightsView extends ConsumerWidget {
  const SellerInsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsProvider);
    final notifier = ref.read(insightsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state, notifier),
            Expanded(
              child: _buildBody(context, state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    InsightsState state,
    InsightsNotifier notifier,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_ios_new,
                size: 18.sp, color: AppColors.textDark),
          ),
          SizedBox(width: 12.w),
          Text(
            'My Insights',
            style: AppTextStyle.headingSm.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showDateRangePicker(context, state, notifier),
            child: Icon(Icons.calendar_month_outlined,
                size: 22.sp, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    InsightsState state,
    InsightsNotifier notifier,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings card (always visible)
          _buildEarningsCard(state, notifier),

          if (state.isLoading) ...[
            SizedBox(height: 80.h),
            const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary500, strokeWidth: 2),
            ),
          ] else if (!state.hasData) ...[
            _buildEmptyBody(context),
          ] else ...[
            SizedBox(height: 20.h),
            _buildStatsRow(state.data),
            SizedBox(height: 20.h),
            _buildSmartInsights(),
            SizedBox(height: 20.h),
            _buildTopListings(state.data.topListings),
            SizedBox(height: 20.h),
            _buildHotZones(context, state.data.hotZones),
            SizedBox(height: 24.h),
            _buildBottomStats(state.data),
            SizedBox(height: 32.h),
          ],
        ],
      ),
    );
  }

  // ── Earnings card ────────────────────────────────────────────────────────────

  Widget _buildEarningsCard(InsightsState state, InsightsNotifier notifier) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period tabs
          Row(
            children: InsightsPeriod.values.map((period) {
              final isSelected = state.period == period;
              final label = switch (period) {
                InsightsPeriod.today => 'Today',
                InsightsPeriod.week => 'Week',
                InsightsPeriod.month => 'Month',
              };
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: GestureDetector(
                  onTap: () => notifier.setPeriod(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary500
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyle.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.white : AppColors.textGrey,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 14.h),

          // Earnings label
          Text(
            'Total Earnings (${_periodLabel(state.period)})',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.h),

          // Earnings amount + change badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatNaira(state.data.totalEarnings),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.verifiedGreen,
                ),
              ),
              if (state.hasData &&
                  state.data.earningsChangePct.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.verifiedGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward_rounded,
                          size: 10.sp, color: AppColors.verifiedGreen),
                      SizedBox(width: 2.w),
                      Text(
                        state.data.earningsChangePct,
                        style: AppTextStyle.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.verifiedGreen,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Line chart (only when data is loaded)
          if (state.hasData && state.data.chartPoints.isNotEmpty) ...[
            SizedBox(height: 18.h),
            _buildLineChart(state.data),
          ],
        ],
      ),
    );
  }

  // ── Line chart ───────────────────────────────────────────────────────────────

  Widget _buildLineChart(InsightsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hourly Earnings',
          style: AppTextStyle.labelMd.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Track your daily performance',
          style: AppTextStyle.bodySm.copyWith(
            color: AppColors.textGrey,
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 130.h,
          child: CustomPaint(
            size: Size(double.infinity, 130.h),
            painter: _LineChartPainter(
              points: data.chartPoints,
              yLabels: data.chartYLabels,
              yMax: data.chartYMax,
              lineColor: AppColors.primary500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats row ────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(InsightsData data) {
    return SizedBox(
      height: 90.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildStatCard(
            icon: Icons.shopping_bag_outlined,
            iconBg: AppColors.primary200,
            iconColor: AppColors.primary600,
            value: '${data.totalOrders}',
            label: 'Total Orders',
            changePct: data.ordersChangePct,
          ),
          SizedBox(width: 10.w),
          _buildStatCard(
            icon: Icons.inventory_2_outlined,
            iconBg: AppColors.primary200,
            iconColor: AppColors.primary600,
            value: '${data.totalHustles}',
            label: 'Total Hustles',
            changePct: data.hustlesChangePct,
          ),
          SizedBox(width: 10.w),
          _buildStatCard(
            icon: Icons.remove_red_eye_outlined,
            iconBg: const Color(0xFFE8F0FE),
            iconColor: const Color(0xFF3B6FE5),
            value: '${data.totalViews}',
            label: 'Total Views',
            changePct: '',
          ),
          SizedBox(width: 16.w),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String changePct,
  }) {
    return Container(
      width: 130.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 14.sp, color: iconColor),
              ),
              const Spacer(),
              if (changePct.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 9.sp, color: AppColors.verifiedGreen),
                    SizedBox(width: 1.w),
                    Text(
                      changePct,
                      style: AppTextStyle.bodySm.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.verifiedGreen,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                label,
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Smart Insights ───────────────────────────────────────────────────────────

  Widget _buildSmartInsights() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primary300.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
              child: Row(
                children: [
                  Text('⚡', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 6.w),
                  Text(
                    'Smart Insights',
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            _buildInsightDivider(),
            _buildInsightItem(
              iconBg: const Color(0xFFE8F5E9),
              iconEmoji: '🏆',
              title: 'Hustle Efficiency',
              body: 'You are ',
              highlight: '5 mins faster',
              suffix: ' than the average Hustler. Keep it up!',
              action: null,
            ),
            _buildInsightDivider(),
            _buildInsightItem(
              iconBg: const Color(0xFFFFF3E0),
              iconEmoji: '📈',
              title: 'Market Trends',
              body: "Users are searching for ",
              highlight: "'Indomie' 200% more",
              suffix: ' this week.',
              action: _InsightAction(
                label: 'Add to your store →',
                isButton: false,
              ),
            ),
            _buildInsightDivider(),
            _buildInsightItem(
              iconBg: AppColors.primary200,
              iconEmoji: '🎁',
              title: 'Top Buyer',
              body: '',
              highlight: 'Adaeze N.',
              suffix: ' has ordered from you 5 times this month.',
              action: _InsightAction(
                label: 'Offer Discount',
                isButton: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightDivider() {
    return Divider(
        height: 1, thickness: 1, color: AppColors.primary300.withOpacity(0.3));
  }

  Widget _buildInsightItem({
    required Color iconBg,
    required String iconEmoji,
    required String title,
    required String body,
    required String highlight,
    required String suffix,
    required _InsightAction? action,
  }) {
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(iconEmoji, style: TextStyle(fontSize: 16.sp)),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                RichText(
                  text: TextSpan(
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 12.sp,
                      height: 1.5,
                    ),
                    children: [
                      if (body.isNotEmpty) TextSpan(text: body),
                      TextSpan(
                        text: highlight,
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.primary600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                      if (suffix.isNotEmpty) TextSpan(text: suffix),
                    ],
                  ),
                ),
                if (action != null) ...[
                  SizedBox(height: 8.h),
                  if (action.isButton)
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary500,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          action.label,
                          style: AppTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        action.label,
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.primary600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Listings ──────────────────────────────────────────────────────────────

  Widget _buildTopListings(List<TopListing> listings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Text(
                'Top Listings',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.primary600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        ...listings.asMap().entries.map((entry) {
          return _buildTopListingItem(entry.key + 1, entry.value);
        }),
      ],
    );
  }

  Widget _buildTopListingItem(int rank, TopListing listing) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              color: AppColors.secondary500,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Product image placeholder
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.primary200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                listing.name[0],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary600,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Name + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.name,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: listing.progress,
                    backgroundColor: AppColors.grey50,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary500),
                    minHeight: 5.h,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Price + views
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                listing.formattedPrice,
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${listing.views} views',
                style: AppTextStyle.bodySm.copyWith(
                  fontSize: 10.sp,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hot Zones ─────────────────────────────────────────────────────────────────

  Widget _buildHotZones(BuildContext context, List<HotZone> zones) {
    final maxPct = zones.isEmpty ? 1 : zones.first.percentage;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16.sp, color: AppColors.primary600),
              SizedBox(width: 4.w),
              Text(
                'Hot Zones',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Where your customers are located',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 14.h),
          ...zones.map((zone) => _buildHotZoneItem(zone, maxPct)),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () => context.pushNamed(RouteNames.serviceAreaManagement),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.grey50),
              ),
              child: Center(
                child: Text(
                  'Expand Coverage Area',
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotZoneItem(HotZone zone, int maxPct) {
    final fraction = maxPct > 0 ? zone.percentage / maxPct : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  zone.name,
                  style: AppTextStyle.bodySm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${zone.ordersCount} orders',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.secondary500,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '${zone.percentage}%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.grey50,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.secondary500),
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Stats ─────────────────────────────────────────────────────────────

  Widget _buildBottomStats(InsightsData data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildBottomStat(data.avgRating, 'Avg Rating'),
          _buildStatDivider(),
          _buildBottomStat(data.avgDeliveryTime, 'Avg Delivery'),
          _buildStatDivider(),
          _buildBottomStat(
            data.successRate,
            'Success Rate',
            valueColor: AppColors.verifiedGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStat(String value, String label,
      {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36.h,
      color: AppColors.grey50,
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────

  Widget _buildEmptyBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 48.h),
          Container(
            width: 108.w,
            height: 108.w,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 48.sp,
              color: AppColors.grey500,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No Data Available',
            style: AppTextStyle.headingSm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.secondary500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start selling to see your performance analytics here',
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pushNamed(RouteNames.addStoreItem),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary500,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r)),
                elevation: 0,
              ),
              child: Text(
                'Add Products',
                style: AppTextStyle.bodyMd.copyWith(
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

  // ── Date range picker ─────────────────────────────────────────────────────────

  void _showDateRangePicker(
    BuildContext context,
    InsightsState state,
    InsightsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateRangePickerSheet(
        currentPeriod: state.period,
        onApply: (period) {
          notifier.setPeriod(period);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _periodLabel(InsightsPeriod period) {
    return switch (period) {
      InsightsPeriod.today => 'Today',
      InsightsPeriod.week => 'This Week',
      InsightsPeriod.month => 'This Month',
    };
  }

  String _formatNaira(double amount) {
    if (amount == 0) return '₦0';
    final parts = amount.toStringAsFixed(0).split('');
    final result = StringBuffer('₦');
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write(',');
      result.write(parts[i]);
    }
    return result.toString();
  }
}

// ── Insight action model ──────────────────────────────────────────────────────

class _InsightAction {
  final String label;
  final bool isButton;
  const _InsightAction({required this.label, required this.isButton});
}

// ── Line chart painter ────────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final List<String> yLabels;
  final double yMax;
  final Color lineColor;

  const _LineChartPainter({
    required this.points,
    required this.yLabels,
    required this.yMax,
    required this.lineColor,
  });

  static const double _leftPad = 38;
  static const double _bottomPad = 20;
  static const double _topPad = 6;
  static const double _rightPad = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || yMax == 0) return;

    final plotW = size.width - _leftPad - _rightPad;
    final plotH = size.height - _bottomPad - _topPad;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.14)
      ..strokeWidth = 1;

    // Y-axis labels + horizontal gridlines
    final yCount = yLabels.length;
    for (int i = 0; i < yCount; i++) {
      final fraction = i / (yCount - 1);
      final y = _topPad + plotH - fraction * plotH;

      // gridline
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(_leftPad + plotW, y),
        gridPaint,
      );

      // label
      final tp = TextPainter(
        text: TextSpan(
          text: yLabels[i],
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            color: Colors.grey[400],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Map points → canvas positions
    final n = points.length;
    final offsets = List.generate(n, (i) {
      final x = _leftPad + (n == 1 ? plotW / 2 : i / (n - 1) * plotW);
      final y = _topPad + plotH - (points[i].amount / yMax).clamp(0.0, 1.0) * plotH;
      return Offset(x, y);
    });

    // Smooth bezier line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (offsets.length >= 2) {
      final path = Path()..moveTo(offsets[0].dx, offsets[0].dy);
      for (int i = 0; i < offsets.length - 1; i++) {
        final p0 = offsets[i];
        final p1 = offsets[i + 1];
        final cpx1 = p0.dx + (p1.dx - p0.dx) / 2.5;
        final cpx2 = p1.dx - (p1.dx - p0.dx) / 2.5;
        path.cubicTo(cpx1, p0.dy, cpx2, p1.dy, p1.dx, p1.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Data-point markers (filled arrow/diamond shapes)
    for (final offset in offsets) {
      _drawArrowMarker(canvas, offset, lineColor);
    }

    // X-axis labels
    for (int i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 8,
            color: Colors.grey[400],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = offsets[i].dx;
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
    }
  }

  void _drawArrowMarker(Canvas canvas, Offset center, Color color) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Small rotated square (diamond)
    const size = 5.0;
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size, center.dy)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.points != points || old.yMax != yMax;
}

// ── Date Range Picker Sheet ───────────────────────────────────────────────────

class _DateRangePickerSheet extends StatefulWidget {
  final InsightsPeriod currentPeriod;
  final void Function(InsightsPeriod) onApply;

  const _DateRangePickerSheet({
    required this.currentPeriod,
    required this.onApply,
  });

  @override
  State<_DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<_DateRangePickerSheet> {
  late _QuickSelect _selected;
  late DateTime _displayMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime.now();
    _selected = switch (widget.currentPeriod) {
      InsightsPeriod.today => _QuickSelect.today,
      InsightsPeriod.week => _QuickSelect.thisWeek,
      InsightsPeriod.month => _QuickSelect.thisMonth,
    };
    _selectedDay = _highlightedDay();
  }

  DateTime _highlightedDay() {
    final now = DateTime.now();
    return switch (_selected) {
      _QuickSelect.today => now,
      _QuickSelect.thisWeek => now.subtract(Duration(days: now.weekday - 1)),
      _QuickSelect.thisMonth => DateTime(now.year, now.month, 1),
      _QuickSelect.thisYear => DateTime(now.year, 1, 1),
    };
  }

  InsightsPeriod _toPeriod() {
    return switch (_selected) {
      _QuickSelect.today => InsightsPeriod.today,
      _QuickSelect.thisWeek => InsightsPeriod.week,
      _QuickSelect.thisMonth || _QuickSelect.thisYear => InsightsPeriod.month,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Header
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.calendar_month_outlined,
                    size: 16.sp, color: AppColors.primary600),
              ),
              SizedBox(width: 10.w),
              Text(
                'Select Date Range',
                style: AppTextStyle.headingSm.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close,
                    size: 20.sp, color: AppColors.textGrey),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Quick select label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'QUICK SELECT',
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.textGrey,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Quick select grid
          Row(
            children: [
              _quickSelectBtn(_QuickSelect.today, 'Today'),
              SizedBox(width: 10.w),
              _quickSelectBtn(_QuickSelect.thisWeek, 'This Week'),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _quickSelectBtn(_QuickSelect.thisMonth, 'This Month'),
              SizedBox(width: 10.w),
              _quickSelectBtn(_QuickSelect.thisYear, 'This Year'),
            ],
          ),
          SizedBox(height: 20.h),

          // Calendar
          _buildCalendar(),
          SizedBox(height: 20.h),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(color: AppColors.grey50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r)),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_toPeriod()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary500,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Apply',
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickSelectBtn(_QuickSelect option, String label) {
    final isSelected = _selected == option;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selected = option;
            _selectedDay = _highlightedDay();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary500 : AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? AppColors.primary500 : AppColors.grey50,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyle.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textDark : AppColors.textGrey,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        // Month navigation
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _displayMonth =
                    DateTime(_displayMonth.year, _displayMonth.month - 1);
              }),
              child: Icon(Icons.chevron_left,
                  size: 22.sp, color: AppColors.textDark),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthLabel(_displayMonth),
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _displayMonth =
                    DateTime(_displayMonth.year, _displayMonth.month + 1);
              }),
              child: Icon(Icons.chevron_right,
                  size: 22.sp, color: AppColors.textDark),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Day-of-week headers
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: 8.h),

        // Day grid
        ..._buildDayRows(),
      ],
    );
  }

  List<Widget> _buildDayRows() {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;

    final cells = <int?>[
      ...List<int?>.filled(startWeekday, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];
    // Pad to full weeks
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final rows = <Widget>[];
    for (int r = 0; r < cells.length ~/ 7; r++) {
      rows.add(
        Row(
          children: List.generate(7, (c) {
            final day = cells[r * 7 + c];
            if (day == null) return const Expanded(child: SizedBox());
            final date =
                DateTime(_displayMonth.year, _displayMonth.month, day);
            final isSelected = _selectedDay != null &&
                date.year == _selectedDay!.year &&
                date.month == _selectedDay!.month &&
                date.day == _selectedDay!.day;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = date),
                child: Container(
                  height: 36.h,
                  margin: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary500
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: AppTextStyle.bodySm.copyWith(
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.textDark
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
      rows.add(SizedBox(height: 2.h));
    }
    return rows;
  }

  String _monthLabel(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

enum _QuickSelect { today, thisWeek, thisMonth, thisYear }
