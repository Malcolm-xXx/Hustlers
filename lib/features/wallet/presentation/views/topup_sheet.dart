import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/topup_provider.dart';

class TopUpSheet extends ConsumerStatefulWidget {
  const TopUpSheet({super.key});

  @override
  ConsumerState<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<TopUpSheet> {
  final _amountController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(topUpProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(topUpProvider);

    // Propagate error via snackbar, then clear it
    ref.listen(topUpProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
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
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildStep(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, TopUpState state) {
    switch (state.step) {
      case TopUpStep.amount:
        return _AmountStep(
          key: const ValueKey('amount'),
          controller: _amountController,
          focusNode: _focusNode,
          onContinue: (amount) async {
            ref.read(topUpProvider.notifier).setAmount(amount);
            final url = await ref.read(topUpProvider.notifier).initiateTopup();
            if (!context.mounted) return;
            if (url != null) {
              // Pop the sheet and return the Paystack URL to the caller
              Navigator.of(context).pop(url);
            }
          },
          onClose: () => Navigator.of(context).pop(),
        );
      case TopUpStep.processing:
        return _ProcessingStep(key: const ValueKey('processing'));
      case TopUpStep.success:
        return _SuccessStep(
          key: const ValueKey('success'),
          amount: state.amount,
          newBalance: state.newBalance,
          onDone: () => Navigator.of(context).pop(),
        );
    }
  }
}

// ── Step: Amount ─────────────────────────────────────────────────────────────

class _AmountStep extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function(double) onContinue;
  final VoidCallback onClose;

  const _AmountStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onContinue,
    required this.onClose,
  });

  @override
  State<_AmountStep> createState() => _AmountStepState();
}

class _AmountStepState extends State<_AmountStep> {
  bool _loading = false;

  double get _amount {
    final raw = widget.controller.text.replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  final _chips = [1000.0, 2000.0, 5000.0, 10000.0];
  double? _selectedChip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusNode.requestFocus();
    });
  }

  void _pickChip(double v) {
    setState(() => _selectedChip = v);
    widget.controller.text = _fmt(v);
  }

  String _fmt(double v) {
    return v.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Future<void> _submit() async {
    if (_loading || _amount <= 0) return;
    setState(() => _loading = true);
    try {
      await widget.onContinue(_amount);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAmount = _amount > 0;

    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: 32.h),
        Text(
          'ENTER AMOUNT',
          style: AppTextStyle.bodySm.copyWith(
            color: AppColors.textGrey,
            letterSpacing: 0.8,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12.h),
        // Amount display
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₦',
                style: AppTextStyle.bodyMd.copyWith(
                  fontSize: 26.sp,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CommaFormatter(),
                  ],
                  textAlign: TextAlign.left,
                  onChanged: (_) => setState(() => _selectedChip = null),
                  style: AppTextStyle.headingSm.copyWith(
                    fontSize: 44.sp,
                    fontWeight: FontWeight.w800,
                    color: hasAmount ? AppColors.textDark : AppColors.grey500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: AppTextStyle.headingSm.copyWith(
                      fontSize: 44.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey500,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Divider(
              color: AppColors.grey500.withValues(alpha: 0.4), height: 1),
        ),
        SizedBox(height: 24.h),
        // Quick chips
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: _chips.map((c) {
              final selected = _selectedChip == c;
              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: c == _chips.last ? 0 : 8.w),
                  child: GestureDetector(
                    onTap: () => _pickChip(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.secondary500
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: selected
                              ? AppColors.secondary500
                              : AppColors.grey500.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '₦${c >= 1000 ? '${(c / 1000).toInt()}k' : c.toInt()}',
                          style: AppTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.white
                                : AppColors.textDark,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 20.h),
        // Info note
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE6),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bolt_rounded,
                    size: 16.sp, color: AppColors.primary600),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'You will be redirected to a secure Paystack page to complete your payment.',
                    style: AppTextStyle.bodySm.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasAmount && !_loading ? _submit : null,
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
              child: _loading
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Top Up Now',
                      style: AppTextStyle.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasAmount
                            ? AppColors.white
                            : AppColors.textGrey,
                        fontSize: 15.sp,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Add Funds',
            style: AppTextStyle.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: widget.onClose,
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
    );
  }
}

// ── Step: Processing ──────────────────────────────────────────────────────────

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80.r,
            height: 80.r,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: AppColors.primary500,
              backgroundColor: AppColors.primary500.withValues(alpha: 0.15),
            ),
          ),
          SizedBox(height: 28.h),
          Text(
            'Processing...',
            style: AppTextStyle.headingSm.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 22.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Setting up your payment.\nThis usually takes a few moments.',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step: Success ─────────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  final double amount;
  final double newBalance;
  final VoidCallback onDone;

  const _SuccessStep({
    super.key,
    required this.amount,
    required this.newBalance,
    required this.onDone,
  });

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 64.r,
                height: 64.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: AppColors.white, size: 32.sp),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                      color: AppColors.primary500, shape: BoxShape.circle)),
              SizedBox(width: 8.w),
              Text(
                'Funds Added!',
                style: AppTextStyle.headingSm.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                      color: AppColors.primary500, shape: BoxShape.circle)),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Your wallet has been topped up',
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.textGrey,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 28.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1A28),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Text(
                  'NEW WALLET BALANCE',
                  style: AppTextStyle.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11.sp,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 10.h),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₦${_fmt(newBalance)}',
                        style: AppTextStyle.headingSm.copyWith(
                          color: AppColors.white,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '.00',
                        style: AppTextStyle.bodyMd.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.south_west,
                        size: 14.sp, color: AppColors.primary500),
                    SizedBox(width: 6.w),
                    Text(
                      '+₦${_fmt(amount)} added',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.primary500,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
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
                'Done',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

// ── Input formatter ───────────────────────────────────────────────────────────

class _CommaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    if (next.text.isEmpty) return next;
    final digits = next.text.replaceAll(',', '');
    final n = int.tryParse(digits) ?? 0;
    final formatted = n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
