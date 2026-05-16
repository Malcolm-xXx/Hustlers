import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/loan_provider.dart';
import 'loan_sheet.dart';

class MicroLoanView extends ConsumerStatefulWidget {
  const MicroLoanView({super.key});

  @override
  ConsumerState<MicroLoanView> createState() => _MicroLoanViewState();
}

class _MicroLoanViewState extends ConsumerState<MicroLoanView> {
  static const double _hustleScore = 724;
  static const double _hustleMax = 1000;
  static const double _maxEligible = 25000;

  static const _amounts = [5000.0, 10000.0, 15000.0, 25000.0];
  static const _periods = [
    (weeks: 2, label: '2 Weeks', fee: 'No fee'),
    (weeks: 4, label: '4 Weeks', fee: 'No fee'),
    (weeks: 6, label: '6 Weeks', fee: '+₦250'),
    (weeks: 8, label: '8 Weeks', fee: '+₦500'),
  ];

  static const _howItWorks = [
    (
      icon: Icons.bolt_rounded,
      title: 'Instant Approval',
      desc:
          'Get approved in seconds based on your hustle score. No paperwork.',
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      title: 'Funds in Wallet',
      desc:
          'Money lands in your Hustler wallet immediately after approval.',
    ),
    (
      icon: Icons.trending_up_rounded,
      title: 'Auto-Repayment',
      desc:
          'Repayments are auto-deducted from your earnings. Zero stress.',
    ),
  ];

  void _openLoanSheet(BuildContext context, LoanState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LoanSheet(
        amount: state.selectedAmount!,
        weeks: state.selectedWeeks!,
        totalRepayable: state.totalRepayable,
      ),
    );
  }

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _shortAmount(double amount) =>
      '₦${(amount / 1000).toInt()}k';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loanProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    _buildHustleScoreCard(),
                    SizedBox(height: 12.h),
                    _buildMaxEligibleCard(),
                    SizedBox(height: 24.h),
                    _buildChooseAmount(state),
                    SizedBox(height: 24.h),
                    _buildRepaymentPeriod(state),
                    if (state.isReady) ...[
                      SizedBox(height: 24.h),
                      _buildLoanSummary(state),
                    ],
                    SizedBox(height: 24.h),
                    _buildHowItWorks(),
                    SizedBox(height: 24.h),
                    _buildInfoBanner(),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildApplyButton(context, state),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Row(
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
          Text(
            'Micro-Loan',
            style: AppTextStyle.headingSm.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHustleScoreCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1A28),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            // Circular gauge
            SizedBox(
              width: 82.r,
              height: 82.r,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 82.r,
                    height: 82.r,
                    child: CircularProgressIndicator(
                      value: _hustleScore / _hustleMax,
                      strokeWidth: 7,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF34C759)),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_hustleScore.toInt()}',
                        style: AppTextStyle.headingSm.copyWith(
                          color: AppColors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/${_hustleMax.toInt()}',
                        style: AppTextStyle.bodySm.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11.sp,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top 28% of hustlers',
                    style: AppTextStyle.bodySm.copyWith(
                      color: const Color(0xFF34C759),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _statRow('Orders Completed', '42'),
                  SizedBox(height: 6.h),
                  _statRow('Avg Rating', '4.8 ★'),
                  SizedBox(height: 6.h),
                  _statRow('On-time Rate', '94%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      children: [
        Container(
          width: 6.r,
          height: 6.r,
          decoration: const BoxDecoration(
            color: Color(0xFF34C759),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: AppTextStyle.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11.sp,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyle.bodySm.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildMaxEligibleCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFE6A800), Color(0xFFFFCB2A)],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MAX ELIGIBLE LOAN',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textDark.withValues(alpha: 0.55),
                      fontSize: 11.sp,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '₦${_fmt(_maxEligible)}',
                    style: AppTextStyle.headingSm.copyWith(
                      color: AppColors.textDark,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.diamond_outlined,
                          size: 13.sp, color: AppColors.textDark),
                      SizedBox(width: 5.w),
                      Text(
                        '0% Interest on your first loan',
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textDark,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined,
                  color: AppColors.textDark, size: 24.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChooseAmount(LoanState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CHOOSE AMOUNT'),
          SizedBox(height: 12.h),
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _amountChip(_amounts[0], state)),
                  SizedBox(width: 12.w),
                  Expanded(child: _amountChip(_amounts[1], state)),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _amountChip(_amounts[2], state)),
                  SizedBox(width: 12.w),
                  Expanded(child: _amountChip(_amounts[3], state)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountChip(double amount, LoanState state) {
    final selected = state.selectedAmount == amount;
    return GestureDetector(
      onTap: () => ref.read(loanProvider.notifier).selectAmount(amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary500 : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? AppColors.secondary500
                : AppColors.grey500.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _shortAmount(amount),
              style: AppTextStyle.bodyMd.copyWith(
                color: selected ? AppColors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 17.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '₦${_fmt(amount)}',
              style: AppTextStyle.bodySm.copyWith(
                color: selected
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppColors.textGrey,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepaymentPeriod(LoanState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('REPAYMENT PERIOD'),
          SizedBox(height: 12.h),
          Row(
            children: _periods.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final selected = state.selectedWeeks == p.weeks;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(loanProvider.notifier).selectWeeks(p.weeks),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: i < 3 ? 8.w : 0),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.secondary500
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selected
                            ? AppColors.secondary500
                            : AppColors.grey500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.label,
                          style: AppTextStyle.bodySm.copyWith(
                            color: selected
                                ? AppColors.white
                                : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          p.fee,
                          style: AppTextStyle.bodySm.copyWith(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppColors.textGrey,
                            fontSize: 10.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  Widget _buildLoanSummary(LoanState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border:
              Border.all(color: AppColors.grey500.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _sectionLabel('LOAN SUMMARY'),
              ),
            ),
            _summaryRow(
                'Principal', '₦${_fmt(state.selectedAmount!)}'),
            _divider(),
            _summaryRow('Interest Rate', '0% (First Loan!)',
                valueColor: AppColors.primary600),
            _divider(),
            _summaryRow('Extension Fee', 'Free',
                valueColor: AppColors.primary600),
            _divider(),
            _summaryRow(
                'Repayment Period', '${state.selectedWeeks} weeks'),
            _divider(),
            _summaryRow('Repayment Method', 'Auto from earnings',
                valueColor: AppColors.primary600),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Divider(
                  color: AppColors.grey500.withValues(alpha: 0.25),
                  thickness: 1.5,
                  height: 1),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Repayable',
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '₦${_fmt(state.totalRepayable)}',
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.sp,
                      color: AppColors.textDark,
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

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
            ),
          ),
          Text(
            value,
            style: AppTextStyle.bodySm.copyWith(
              color: valueColor ?? AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child:
            Divider(color: AppColors.grey500.withValues(alpha: 0.2), height: 1),
      );

  Widget _buildHowItWorks() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('HOW IT WORKS'),
          SizedBox(height: 12.h),
          ..._howItWorks.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1A28),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child:
                        Icon(item.icon, color: AppColors.primary500, size: 22.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyle.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          item.desc,
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 12.sp,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
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
                size: 16.sp, color: const Color(0xFF007AFF)),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Your score updates in real-time with every completed order and rating received. Complete more orders to unlock higher limits.',
                style: AppTextStyle.bodySm.copyWith(
                  color: const Color(0xFF007AFF),
                  fontSize: 12.sp,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, LoanState state) {
    final enabled = state.selectedAmount != null;
    final label = state.selectedAmount != null
        ? 'Apply for ₦${_fmt(state.selectedAmount!)} Loan'
        : 'Apply for Loan';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? () => _openLoanSheet(context, state) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary500,
              disabledBackgroundColor:
                  AppColors.grey500.withValues(alpha: 0.3),
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r)),
              elevation: 0,
            ),
            child: Text(
              label,
              style: AppTextStyle.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.white : AppColors.textGrey,
                fontSize: 15.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyle.bodySm.copyWith(
        color: AppColors.textGrey,
        fontSize: 11.sp,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
