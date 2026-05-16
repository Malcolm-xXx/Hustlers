import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/savings_provider.dart';
import 'withdraw_savings_sheet.dart';

String _fmt(double v) => v
    .toInt()
    .toString()
    .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

class HustleSavingsView extends ConsumerWidget {
  const HustleSavingsView({super.key});

  void _openWithdraw(BuildContext context, double available) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawSavingsSheet(availableAmount: available),
    );
  }

  void _showPercentagePicker(
      BuildContext context, WidgetRef ref, int current) {
    const options = [5, 10, 15, 20];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey500.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Save Percentage',
              style: AppTextStyle.headingSm.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ...options.map((pct) {
              final selected = pct == current;
              return GestureDetector(
                onTap: () {
                  ref.read(savingsProvider.notifier).setSavePercentage(pct);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary100
                        : AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary500
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$pct% of every payout',
                        style: AppTextStyle.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check_circle,
                            color: AppColors.primary600, size: 20.sp),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    _buildTotalSavedCard(state),
                    SizedBox(height: 16.h),
                    _buildAutoSaveCard(context, ref, state),
                    SizedBox(height: 12.h),
                    _buildInterestCard(),
                    SizedBox(height: 12.h),
                    _buildSaveAlertsCard(ref, state),
                    SizedBox(height: 12.h),
                    _buildWithdrawalLockCard(state),
                    SizedBox(height: 16.h),
                    _buildWithdrawButton(context, state),
                    SizedBox(height: 24.h),
                    _buildSavingsActivity(state),
                    SizedBox(height: 16.h),
                    _buildDisclaimer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  size: 16.sp, color: AppColors.textDark),
            ),
          ),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hustle Savings',
                style: AppTextStyle.headingSm.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                ),
              ),
              Text(
                'Auto-Save from every payout',
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

  Widget _buildTotalSavedCard(SavingsState state) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
    final maxValue = state.monthlyValues.isEmpty
        ? 1.0
        : state.monthlyValues.reduce((a, b) => a > b ? a : b);
    final selectedIdx = state.monthlyValues.length - 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1A28),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TOTAL SAVED',
                  style: AppTextStyle.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11.sp,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF34C759).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '8% p.a.',
                    style: AppTextStyle.bodySm.copyWith(
                      color: const Color(0xFF34C759),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '₦',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: _fmt(state.totalSaved),
                    style: AppTextStyle.headingSm.copyWith(
                      color: AppColors.white,
                      fontSize: 38.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: '.00',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    color: const Color(0xFF34C759), size: 14.sp),
                SizedBox(width: 4.w),
                Text(
                  '+₦${state.interestEarned.toStringAsFixed(2)} Interest earned',
                  style: AppTextStyle.bodySm.copyWith(
                    color: const Color(0xFF34C759),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            SizedBox(
              height: 60.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(state.monthlyValues.length, (i) {
                  final isSelected = i == selectedIdx;
                  final barH =
                      (state.monthlyValues[i] / maxValue) * 56.h;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: barH.clamp(6.0, 56.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary500
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4.r),
                                topRight: Radius.circular(4.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: List.generate(months.length, (i) {
                final isSelected = i == selectedIdx;
                return Expanded(
                  child: Text(
                    months[i],
                    textAlign: TextAlign.center,
                    style: AppTextStyle.bodySm.copyWith(
                      color: isSelected
                          ? AppColors.primary500
                          : Colors.white.withValues(alpha: 0.35),
                      fontSize: 10.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 16.h),
            Divider(
                color: Colors.white.withValues(alpha: 0.1), height: 1),
            SizedBox(height: 14.h),
            Row(
              children: [
                _statCell(
                    'This Month',
                    '₦${state.thisMonthSaved.toStringAsFixed(2)}'),
                Container(
                    width: 1,
                    height: 28.h,
                    color: Colors.white.withValues(alpha: 0.12)),
                _statCell(
                    'Total Interest',
                    '₦${state.interestEarned.toStringAsFixed(2)}'),
                Container(
                    width: 1,
                    height: 28.h,
                    color: Colors.white.withValues(alpha: 0.12)),
                _statCell('Auto-Save', '${state.autoSaveCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: AppTextStyle.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSaveCard(
      BuildContext context, WidgetRef ref, SavingsState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Save',
                        style: AppTextStyle.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '10% of every payout saved automatically',
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.autoSaveEnabled,
                  onChanged: (_) =>
                      ref.read(savingsProvider.notifier).toggleAutoSave(),
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.primary500,
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor:
                      AppColors.grey500.withValues(alpha: 0.4),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Divider(
                color: AppColors.grey500.withValues(alpha: 0.2), height: 1),
            SizedBox(height: 12.h),
            Row(
              children: [
                Text(
                  'Save percentage',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 13.sp,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showPercentagePicker(
                      context, ref, state.savePercentage),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color:
                              AppColors.grey500.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${state.savePercentage}%',
                          style: AppTextStyle.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16.sp, color: AppColors.textGrey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 14.sp, color: const Color(0xFF34C759)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Next payout: approx. ₦180 saved automatically',
                      style: AppTextStyle.bodySm.copyWith(
                        color: const Color(0xFF34C759),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.percent_rounded,
                      size: 18.sp, color: AppColors.primary600),
                ),
                SizedBox(width: 12.w),
                Text(
                  '8% Annual Interest',
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              'Interest accrues daily and is credited to your savings balance on the 1st of each month. No action needed.',
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.textGrey,
                fontSize: 12.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                _infoChip('8% p.a.', 'Rate'),
                SizedBox(width: 10.w),
                _infoChip('Monthly', 'Compound'),
                SizedBox(width: 10.w),
                _infoChip('7 days', 'Min.Lock'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyle.bodyMd.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.textGrey,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveAlertsCard(WidgetRef ref, SavingsState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.notifications_outlined,
                  size: 18.sp, color: AppColors.primary600),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save Alerts',
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Notify me on each auto-save',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: state.saveAlertsEnabled,
              onChanged: (_) =>
                  ref.read(savingsProvider.notifier).toggleSaveAlerts(),
              activeColor: AppColors.white,
              activeTrackColor: AppColors.primary500,
              inactiveThumbColor: AppColors.white,
              inactiveTrackColor: AppColors.grey500.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalLockCard(SavingsState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.lock_outline,
                  size: 18.sp, color: const Color(0xFFFF9500)),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Withdrawal Lock',
                        style: AppTextStyle.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (state.isWithdrawalLocked) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '${state.daysLeft}d left',
                            style: AppTextStyle.bodySm.copyWith(
                              color: const Color(0xFFFF9500),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    state.isWithdrawalLocked
                        ? 'Unlocks ${state.unlockDate}'
                        : 'Minimum hold period passed',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawButton(BuildContext context, SavingsState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openWithdraw(context, state.totalSaved),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            foregroundColor: AppColors.textDark,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.r)),
            elevation: 0,
          ),
          icon:
              Icon(Icons.account_balance_wallet_outlined, size: 18.sp),
          label: Text(
            'Withdraw to Wallet',
            style: AppTextStyle.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 15.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsActivity(SavingsState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Savings Activity',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'See All',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(Icons.chevron_right,
                      size: 16.sp, color: AppColors.textGrey),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...state.activities.map(
              (a) => _ActivityTile(activity: a)),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF4FF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: const Color(0xFF007AFF).withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 14.sp, color: const Color(0xFF007AFF)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Hustle Savings is not a bank account. Funds are held securely and are not NDIC insured. Interest rates may change with 30-day notice.',
                style: AppTextStyle.bodySm.copyWith(
                  color: const Color(0xFF007AFF),
                  fontSize: 11.sp,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final SavingsActivity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppColors.primary100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.savings_outlined,
                size: 20.sp, color: AppColors.primary600),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.orderRef,
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  activity.date,
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+₦${_fmt(activity.amount)}',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: const Color(0xFF34C759),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                '${activity.percentage}% saved',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
