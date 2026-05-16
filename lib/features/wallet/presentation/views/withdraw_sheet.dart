import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hustlers/core/widgets/app_primary_button.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/otp_input_field.dart';
import '../../data/models/wallet_models.dart';
import '../providers/wallet_provider.dart';
import '../providers/withdraw_provider.dart';

class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({super.key});

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(withdrawProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(withdrawProvider);
    final walletState = ref.watch(walletProvider);

    ref.listen(withdrawProvider, (prev, next) {
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
              child: _buildStep(context, state, walletState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
      BuildContext context, WithdrawState state, WalletState walletState) {
    switch (state.step) {
      case WithdrawStep.amount:
        return _WithdrawAmountStep(
          key: const ValueKey('wd_amount'),
          availableBalance: walletState.balance,
          onContinue: (amount) {
            ref.read(withdrawProvider.notifier).setAmount(amount);
            ref.read(withdrawProvider.notifier).proceed();
          },
          onClose: () => Navigator.of(context).pop(),
        );
      case WithdrawStep.enterAccount:
        return _EnterAccountStep(
          key: const ValueKey('wd_enter'),
          state: state,
          onBack: () => ref.read(withdrawProvider.notifier).back(),
          onBankChanged: (name, code) =>
              ref.read(withdrawProvider.notifier).setBankCode(name, code),
          onAccountNumberChanged: (v) =>
              ref.read(withdrawProvider.notifier).setAccountNumber(v),
          onSubmit: () =>
              ref.read(withdrawProvider.notifier).submitWithdrawal(),
        );
      case WithdrawStep.processing:
        return const _ProcessingStep(key: ValueKey('wd_processing'));
      case WithdrawStep.otp:
        return _WdOtpStep(
          key: const ValueKey('wd_otp'),
          state: state,
          onOtpChanged: (v) =>
              ref.read(withdrawProvider.notifier).setOtp(v),
          onVerify: () =>
              ref.read(withdrawProvider.notifier).finalizeWithdrawal(),
          onResend: () =>
              ref.read(withdrawProvider.notifier).resendOtp(),
        );
      case WithdrawStep.success:
        return _WithdrawSuccessStep(
          key: const ValueKey('wd_success'),
          amount: state.amount,
          account: state.selectedAccount!,
          onDone: () => Navigator.of(context).pop(),
        );
    }
  }
}

// ── Step: Withdraw Amount ─────────────────────────────────────────────────────

class _WithdrawAmountStep extends StatefulWidget {
  final double availableBalance;
  final void Function(double) onContinue;
  final VoidCallback onClose;

  const _WithdrawAmountStep({
    super.key,
    required this.availableBalance,
    required this.onContinue,
    required this.onClose,
  });

  @override
  State<_WithdrawAmountStep> createState() => _WithdrawAmountStepState();
}

class _WithdrawAmountStepState extends State<_WithdrawAmountStep> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double get _amount {
    final raw = _controller.text.replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  bool get _isValid => _amount > 0 && _amount <= widget.availableBalance;

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _setMax() {
    _controller.text = _fmt(widget.availableBalance);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasAmount = _amount > 0;

    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: 12.h),
        _ProgressBar(filledCount: 1, fillColor: AppColors.primary500),
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(12.r),
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
                  '₦${_fmt(widget.availableBalance)}.00',
                  style: AppTextStyle.headingSm.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24.sp,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
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
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _WdCommaFormatter(),
                  ],
                  textAlign: TextAlign.left,
                  onChanged: (_) => setState(() {}),
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
              GestureDetector(
                onTap: _setMax,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary500,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'MAX',
                    style: AppTextStyle.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: 12.sp,
                    ),
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
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValid ? () => widget.onContinue(_amount) : null,
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
                'Continue',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isValid ? AppColors.white : AppColors.textGrey,
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
            'Withdraw Funds',
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

// ── Step: Enter Account ───────────────────────────────────────────────────────

typedef _BankEntry = (String name, String code);

const _kBanks = <_BankEntry>[
  ('Access Bank', '044'),
  ('First Bank', '011'),
  ('GTBank', '058'),
  ('UBA', '033'),
  ('Zenith Bank', '057'),
  ('WEMA Bank', '035'),
  ('Fidelity Bank', '070'),
  ('Union Bank', '032'),
  ('Sterling Bank', '232'),
  ('Kuda Bank', '090267'),
  ('Opay', '100004'),
  ('PalmPay', '100033'),
];

class _EnterAccountStep extends StatefulWidget {
  final WithdrawState state;
  final VoidCallback onBack;
  final void Function(String name, String code) onBankChanged;
  final void Function(String) onAccountNumberChanged;
  final VoidCallback onSubmit;

  const _EnterAccountStep({
    super.key,
    required this.state,
    required this.onBack,
    required this.onBankChanged,
    required this.onAccountNumberChanged,
    required this.onSubmit,
  });

  @override
  State<_EnterAccountStep> createState() => _EnterAccountStepState();
}

class _EnterAccountStepState extends State<_EnterAccountStep> {
  final _acctController = TextEditingController();

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  void dispose() {
    _acctController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 12.h),
          _ProgressBar(filledCount: 2, fillColor: AppColors.primary500),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Text(
              '-₦${_fmt(state.amount)}',
              style: AppTextStyle.bodyMd.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
                color: const Color(0xFFFF3B30),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _formLabel('BANK NAME'),
                  SizedBox(height: 6.h),
                  _BankDropdown(
                    selectedName: state.newBankName,
                    banks: _kBanks,
                    onChanged: widget.onBankChanged,
                  ),
                  SizedBox(height: 12.h),
                  _formLabel('ACCOUNT NUMBER'),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _acctController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: widget.onAccountNumberChanged,
                    decoration: InputDecoration(
                      hintText: '10-digit account number',
                      hintStyle: AppTextStyle.bodySm.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 13.sp,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide:
                            BorderSide(color: AppColors.primary500, width: 1.5),
                      ),
                    ),
                    style: AppTextStyle.bodyMd.copyWith(fontSize: 14.sp),
                  ),
                  if (state.isVerifying) ...[
                    SizedBox(height: 8.h),
                    _verificationBanner(
                      icon: SizedBox(
                        width: 14.r,
                        height: 14.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF34C759),
                        ),
                      ),
                      text: 'Verifying account name...',
                    ),
                  ] else if (state.verifiedAccountName != null) ...[
                    SizedBox(height: 8.h),
                    _verificationBanner(
                      icon: Icon(Icons.check_circle_outline,
                          size: 16.sp, color: const Color(0xFF34C759)),
                      text: state.verifiedAccountName!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    state.canSubmit && !state.isProcessing ? widget.onSubmit : null,
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
                  'Withdraw Now',
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: state.canSubmit
                        ? AppColors.white
                        : AppColors.textGrey,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Enter Bank Account',
            style: AppTextStyle.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: widget.onBack,
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
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: AppTextStyle.bodySm.copyWith(
        color: AppColors.textGrey,
        fontSize: 10.sp,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _verificationBanner({required Widget icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          icon,
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle.bodyMd.copyWith(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankDropdown extends StatelessWidget {
  final String selectedName;
  final List<_BankEntry> banks;
  final void Function(String name, String code) onChanged;

  const _BankDropdown({
    required this.selectedName,
    required this.banks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBankPicker(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 18.sp,
              color: selectedName.isNotEmpty
                  ? AppColors.primary600
                  : AppColors.textGrey,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                selectedName.isEmpty ? 'e.g. First Bank' : selectedName,
                style: AppTextStyle.bodyMd.copyWith(
                  fontSize: 13.sp,
                  color: selectedName.isEmpty
                      ? AppColors.textGrey
                      : AppColors.textDark,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20.sp, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  void _showBankPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey500.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Select Bank',
              style: AppTextStyle.bodyMd
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: banks.length,
                separatorBuilder: (context, index) =>
                    Divider(color: AppColors.grey500.withValues(alpha: 0.2)),
                itemBuilder: (_, i) => ListTile(
                  leading: Icon(Icons.account_balance_outlined,
                      color: AppColors.primary600),
                  title: Text(banks[i].$1),
                  onTap: () {
                    onChanged(banks[i].$1, banks[i].$2);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

// ── Step: OTP Verification ────────────────────────────────────────────────────

class _WdOtpStep extends StatefulWidget {
  final WithdrawState state;
  final void Function(String) onOtpChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _WdOtpStep({
    super.key,
    required this.state,
    required this.onOtpChanged,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<_WdOtpStep> createState() => _WdOtpStepState();
}

class _WdOtpStepState extends State<_WdOtpStep> {
  final _otpController = TextEditingController();

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final canVerify = state.isOtpComplete && !state.isProcessing;

    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: 12.h),
        _ProgressBar(filledCount: 3, fillColor: AppColors.primary500),
        SizedBox(height: 36.h),
        Container(
          width: 72.r,
          height: 72.r,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1A28),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(Icons.sms_outlined,
              size: 36.sp, color: AppColors.primary500),
        ),
        SizedBox(height: 20.h),
        Text(
          'Enter OTP',
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
              const TextSpan(text: 'Enter the OTP sent to authorize\nyour '),
              TextSpan(
                text: '₦${_fmt(state.amount)} withdrawal',
                style: AppTextStyle.bodySm.copyWith(
                  color: const Color(0xFFFF3B30),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32.h),
        OtpInputField(
          controller: _otpController,
          onChanged: widget.onOtpChanged,
          onCompleted: (_) => widget.onVerify(),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canVerify ? widget.onVerify : null,
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
              child: state.isProcessing
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Verify & Complete',
                      style: AppTextStyle.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: canVerify ? AppColors.white : AppColors.textGrey,
                        fontSize: 15.sp,
                      ),
                    ),
            ),
          ),
        ),
        TextButton(
          onPressed: widget.onResend,
          child: Text(
            'Resend OTP',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Center(
        child: Text(
          'OTP Verification',
          style: AppTextStyle.bodyMd.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
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
            "We're securely sending your funds.\nThis usually takes a few moments.",
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

// ── Step: Withdraw Success ────────────────────────────────────────────────────

class _WithdrawSuccessStep extends StatelessWidget {
  final double amount;
  final LinkedBankAccount account;
  final VoidCallback onDone;

  const _WithdrawSuccessStep({
    super.key,
    required this.amount,
    required this.account,
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
                  color: AppColors.primary500.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 64.r,
                height: 64.r,
                decoration: const BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: AppColors.white, size: 32.sp),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'Request Received!',
            style: AppTextStyle.headingSm.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 24.sp,
            ),
          ),
          SizedBox(height: 8.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.textGrey,
                fontSize: 14.sp,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Your withdrawal of '),
                TextSpan(
                  text: '₦${_fmt(amount)}',
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: AppColors.textDark,
                  ),
                ),
                TextSpan(
                    text:
                        ' to\n${account.bankName} is being processed.\nTransfers arrive within 1–3 minutes.'),
              ],
            ),
          ),
          SizedBox(height: 28.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              children: [
                _ReceiptRow(
                    label: 'Destination',
                    value: '${account.bankName} ••••${account.lastFour}'),
                Divider(
                    color: AppColors.grey500.withValues(alpha: 0.2),
                    height: 1,
                    indent: 16.w,
                    endIndent: 16.w),
                _ReceiptRow(label: 'Amount', value: '₦${_fmt(amount)}.00'),
                Divider(
                    color: AppColors.grey500.withValues(alpha: 0.2),
                    height: 1,
                    indent: 16.w,
                    endIndent: 16.w),
                _ReceiptRow(
                    label: 'Status',
                    value: 'Processing',
                    valueColor: const Color(0xFFFF9500)),
                Divider(
                    color: AppColors.grey500.withValues(alpha: 0.2),
                    height: 1,
                    indent: 16.w,
                    endIndent: 16.w),
                const _ReceiptRow(label: 'ETA', value: '1–3 minutes'),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              onPressed: onDone,
              backgroundColor: AppColors.secondary500,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              elevation: 0,
              text: 'Done',
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReceiptRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyle.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared: Progress bar ──────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int filledCount;
  final Color fillColor;

  const _ProgressBar({required this.filledCount, required this.fillColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              height: 3.5.h,
              decoration: BoxDecoration(
                color: i < filledCount
                    ? fillColor
                    : AppColors.grey500.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Input formatter ───────────────────────────────────────────────────────────

class _WdCommaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    if (next.text.isEmpty) return next;
    final digits = next.text.replaceAll(',', '');
    final n = int.tryParse(digits) ?? 0;
    final formatted = n
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
