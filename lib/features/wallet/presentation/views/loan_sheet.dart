import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/wallet_provider.dart';

enum _LoanSheetStep { confirm, security, approved }

class LoanSheet extends ConsumerStatefulWidget {
  final double amount;
  final int weeks;
  final double totalRepayable;

  const LoanSheet({
    super.key,
    required this.amount,
    required this.weeks,
    required this.totalRepayable,
  });

  @override
  ConsumerState<LoanSheet> createState() => _LoanSheetState();
}

class _LoanSheetState extends ConsumerState<LoanSheet> {
  _LoanSheetStep _step = _LoanSheetStep.confirm;
  String _pin = '';
  bool _processing = false;
  late final String _loanRef;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _loanRef = 'CHL-${(100000 + rand.nextInt(900000))}';
  }

  void _enterDigit(String d) {
    if (_pin.length >= 4 || _processing) return;
    setState(() => _pin += d);
    if (_pin.length == 4) _onPinComplete();
  }

  void _deleteDigit() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onPinComplete() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    ref.read(walletProvider.notifier).refresh();
    setState(() {
      _processing = false;
      _step = _LoanSheetStep.approved;
    });
  }

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey500.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _LoanSheetStep.confirm:
        return _ConfirmStep(
          key: const ValueKey('confirm'),
          amount: widget.amount,
          weeks: widget.weeks,
          totalRepayable: widget.totalRepayable,
          onClose: () => Navigator.of(context).pop(),
          onConfirm: () => setState(() => _step = _LoanSheetStep.security),
          fmtFn: _fmt,
        );
      case _LoanSheetStep.security:
        return _SecurityStep(
          key: const ValueKey('security'),
          pin: _pin,
          amount: widget.amount,
          processing: _processing,
          onBack: () => setState(() {
            _step = _LoanSheetStep.confirm;
            _pin = '';
          }),
          onDigit: _enterDigit,
          onDelete: _deleteDigit,
          fmtFn: _fmt,
        );
      case _LoanSheetStep.approved:
        return _ApprovedStep(
          key: const ValueKey('approved'),
          amount: widget.amount,
          totalRepayable: widget.totalRepayable,
          loanRef: _loanRef,
          onDone: () => Navigator.of(context).pop(),
          fmtFn: _fmt,
        );
    }
  }
}

// ── Confirm Step ──────────────────────────────────────────────────────────────

class _ConfirmStep extends StatelessWidget {
  final double amount;
  final int weeks;
  final double totalRepayable;
  final VoidCallback onClose;
  final VoidCallback onConfirm;
  final String Function(double) fmtFn;

  const _ConfirmStep({
    super.key,
    required this.amount,
    required this.weeks,
    required this.totalRepayable,
    required this.onClose,
    required this.onConfirm,
    required this.fmtFn,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Confirm Loan',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 18.sp, color: AppColors.textDark),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Borrowing card
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: AppColors.grey500.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(
                  'YOU\'RE BORROWING',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 11.sp,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '₦${fmtFn(amount)}',
                  style: AppTextStyle.headingSm.copyWith(
                    fontSize: 42.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: const Color(0xFF34C759), size: 14.sp),
                      SizedBox(width: 6.w),
                      Text(
                        '0% Interest – First Loan!',
                        style: AppTextStyle.bodySm.copyWith(
                          color: const Color(0xFF34C759),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Detail rows
          _detailRow(
              'Repayment', '₦${fmtFn(totalRepayable)} over $weeks weeks'),
          Divider(
              color: AppColors.grey500.withValues(alpha: 0.2), height: 24.h),
          _detailRow('Method', 'Auto-deducted from earnings', bold: true),
          Divider(
              color: AppColors.grey500.withValues(alpha: 0.2), height: 24.h),
          _detailRow('Disbursed', 'Instantly to your wallet', bold: true),
          SizedBox(height: 20.h),

          // Warning box
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                  color: AppColors.primary300.withValues(alpha: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 16.sp, color: AppColors.primary600),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'By proceeding, you agree that repayments will be auto-deducted from your hustle earnings until fully settled.',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textDark,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary500,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r)),
                elevation: 0,
              ),
              child: Text(
                'Confirm & Enter PIN',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColors.textGrey,
            fontSize: 14.sp,
          ),
        ),
        Text(
          value,
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColors.textDark,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}

// ── Security Step ─────────────────────────────────────────────────────────────

class _SecurityStep extends StatelessWidget {
  final String pin;
  final double amount;
  final bool processing;
  final VoidCallback onBack;
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final String Function(double) fmtFn;

  const _SecurityStep({
    super.key,
    required this.pin,
    required this.amount,
    required this.processing,
    required this.onBack,
    required this.onDigit,
    required this.onDelete,
    required this.fmtFn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Security Check',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 16.sp, color: AppColors.textDark),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 28.h),

        // Fingerprint icon
        Container(
          width: 72.r,
          height: 72.r,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1A28),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: processing
              ? Center(
                  child: SizedBox(
                    width: 28.r,
                    height: 28.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary500,
                      backgroundColor:
                          AppColors.primary500.withValues(alpha: 0.2),
                    ),
                  ),
                )
              : Icon(Icons.fingerprint, size: 40.sp, color: AppColors.primary500),
        ),
        SizedBox(height: 20.h),
        Text(
          'Confirm with PIN',
          style: AppTextStyle.bodyMd.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        SizedBox(height: 6.h),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
              height: 1.4,
            ),
            children: [
              const TextSpan(
                  text:
                      'Enter your 4-digit transaction PIN to authorize\nthe loan of '),
              TextSpan(
                text: '₦${fmtFn(amount)}',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.primary600,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 28.h),

        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < pin.length;
            return Container(
              width: 16.r,
              height: 16.r,
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: filled ? AppColors.textDark : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: filled
                      ? AppColors.textDark
                      : AppColors.grey500.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 28.h),

        // Numpad
        Expanded(
            child: _Numpad(onDigit: onDigit, onDelete: onDelete)),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: () {},
          child: Text(
            'Use Biometric / Face ID instead',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

// ── Approved Step ─────────────────────────────────────────────────────────────

class _ApprovedStep extends StatelessWidget {
  final double amount;
  final double totalRepayable;
  final String loanRef;
  final VoidCallback onDone;
  final String Function(double) fmtFn;

  const _ApprovedStep({
    super.key,
    required this.amount,
    required this.totalRepayable,
    required this.loanRef,
    required this.onDone,
    required this.fmtFn,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          // Green check circle
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88.r,
                height: 88.r,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 68.r,
                height: 68.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: AppColors.white, size: 34.sp),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'Loan Approved!',
            style: AppTextStyle.headingSm.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 26.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '₦${fmtFn(amount)} has been added to your wallet',
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.textGrey,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 28.h),

          // Details card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1A28),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                _detailRow('Amount Disbursed', '₦${fmtFn(amount)}',
                    valueColor: AppColors.primary500),
                Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 24.h),
                _detailRow('Total Repayable', '₦${fmtFn(totalRepayable)}'),
                Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 24.h),
                _detailRow('First Deduction', 'From your next payout'),
                Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 24.h),
                _detailRow('Loan Ref', loanRef,
                    valueColor: AppColors.primary600),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary500,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r)),
                elevation: 0,
              ),
              child: Text(
                'Done – View Wallet',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyle.bodySm.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13.sp,
          ),
        ),
        Text(
          value,
          style: AppTextStyle.bodyMd.copyWith(
            color: valueColor ?? AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}

// ── Numpad ────────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _Numpad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...rows.map((row) => Row(
                children: row
                    .map((d) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(5.w),
                            child: _NumKey(
                                label: d, onTap: () => onDigit(d)),
                          ),
                        ))
                    .toList(),
              )),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(5.w),
                  child: _NumKey(label: '0', onTap: () => onDigit('0')),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(5.w),
                  child: _DeleteKey(onTap: onDelete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border:
              Border.all(color: AppColors.grey500.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyle.bodyMd.copyWith(
              fontSize: 22.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteKey extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteKey({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(14.r),
          border:
              Border.all(color: AppColors.grey500.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(Icons.backspace_outlined,
              size: 22.sp, color: AppColors.textGrey),
        ),
      ),
    );
  }
}
