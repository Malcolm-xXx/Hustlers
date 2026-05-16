import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/savings_provider.dart';

enum _Step { amount, success }

class WithdrawSavingsSheet extends ConsumerStatefulWidget {
  final double availableAmount;

  const WithdrawSavingsSheet({super.key, required this.availableAmount});

  @override
  ConsumerState<WithdrawSavingsSheet> createState() =>
      _WithdrawSavingsSheetState();
}

class _WithdrawSavingsSheetState
    extends ConsumerState<WithdrawSavingsSheet> {
  _Step _step = _Step.amount;
  String _input = '';

  double get _amount => double.tryParse(_input) ?? 0;
  bool get _canWithdraw =>
      _amount > 0 && _amount <= widget.availableAmount;

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _onKey(String key) {
    if (_input.length < 7) setState(() => _input += key);
  }

  void _onDelete() {
    if (_input.isNotEmpty) {
      setState(
          () => _input = _input.substring(0, _input.length - 1));
    }
  }

  void _onWithdraw() {
    ref.read(savingsProvider.notifier).withdraw(_amount);
    setState(() => _step = _Step.success);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _step == _Step.amount
          ? _buildAmountStep(context)
          : _buildSuccessStep(context),
    );
  }

  Widget _buildAmountStep(BuildContext context) {
    return Container(
      key: const ValueKey('amount'),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close,
                      size: 16.sp, color: AppColors.textDark),
                ),
              ),
              Expanded(
                child: Text(
                  'Withdraw Savings',
                  style: AppTextStyle.headingSm.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 32.r),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available to Withdraw',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '₦${_fmt(widget.availableAmount)}.00',
                  style: AppTextStyle.headingSm.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24.sp,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),
          Text(
            'ENTER AMOUNT',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 11.sp,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₦',
                style: AppTextStyle.headingSm.copyWith(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w700,
                  color: _input.isEmpty
                      ? AppColors.grey500
                      : AppColors.textDark,
                ),
              ),
              Text(
                _input.isEmpty ? '0' : _fmt(_amount),
                style: AppTextStyle.headingSm.copyWith(
                  fontSize: 52.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: _input.isEmpty
                      ? AppColors.grey500
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Center(
            child: Container(
              width: 200.w,
              height: 2.h,
              color: AppColors.grey500.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: 24.h),
          _Numpad(onKey: _onKey, onDelete: _onDelete),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canWithdraw ? _onWithdraw : null,
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
                'Withdraw to Wallet',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _canWithdraw
                      ? AppColors.white
                      : AppColors.textGrey,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
          SizedBox(
              height: 16.h + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    return Container(
      key: const ValueKey('success'),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          SizedBox(height: 40.h),
          Container(
            width: 80.r,
            height: 80.r,
            decoration: const BoxDecoration(
              color: Color(0xFF34C759),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                color: AppColors.white, size: 40.sp),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Withdrawal Successful!',
                  style: AppTextStyle.headingSm.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22.sp,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                Positioned(
                  right: 28.w,
                  top: 2.h,
                  child: Container(
                    width: 9.r,
                    height: 9.r,
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 18.w,
                  bottom: 2.h,
                  child: Container(
                    width: 6.r,
                    height: 6.r,
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '₦${_fmt(_amount)} has been added to your main wallet',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary500,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r)),
                elevation: 0,
              ),
              child: Text(
                'Done',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
          SizedBox(
              height: 24.h + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;

  const _Numpad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0'];

    return Column(
      children: List.generate(4, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (col) {
              final idx = row * 3 + col;
              if (idx < keys.length) {
                return _NumKey(
                    label: keys[idx], onTap: () => onKey(keys[idx]));
              } else if (idx == keys.length) {
                return _DeleteKey(onTap: onDelete);
              }
              return SizedBox(width: 88.w + 12.w);
            }),
          ),
        );
      }),
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
        width: 88.w,
        height: 52.h,
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyle.headingSm.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
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
        width: 88.w,
        height: 52.h,
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 22.sp,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
