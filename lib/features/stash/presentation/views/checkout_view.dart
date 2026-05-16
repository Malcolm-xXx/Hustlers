import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../payments/data/datasources/payment_remote_datasource.dart';
import '../../../payments/data/models/payment_models.dart';
import '../../data/models/stash_models.dart';
import '../providers/checkout_provider.dart';
import '../providers/stash_provider.dart';

class CheckoutView extends ConsumerWidget {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutProvider);
    final stash = ref.watch(stashProvider);

    ref.listen(checkoutProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: 20.h),
            _buildStepper(state.step),
            SizedBox(height: 24.h),
            Expanded(
              child: state.step == CheckoutStep.payment
                  ? _buildPaymentStep(context, ref, state)
                  : _buildReviewStep(context, ref, state, stash),
            ),
            _buildBottomBar(context, ref, state, stash),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_ios_new,
                size: 18.sp, color: AppColors.textDark),
          ),
          SizedBox(width: 10.w),
          Text(
            'Checkout',
            style: AppTextStyle.headingSm.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Stepper ─────────────────────────────────────────────────────────────────

  Widget _buildStepper(CheckoutStep currentStep) {
    // step 0 = Your Stash (always done), 1 = Payment, 2 = Review
    final stepIndex = currentStep == CheckoutStep.payment ? 1 : 2;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          _stepItem(0, stepIndex, 'Your\nStash'),
          _stepConnector(0, stepIndex),
          _stepItem(1, stepIndex, 'Payment'),
          _stepConnector(1, stepIndex),
          _stepItem(2, stepIndex, 'Review'),
        ],
      ),
    );
  }

  Widget _stepItem(int step, int currentStep, String label) {
    final isDone = step < currentStep;
    final isActive = step == currentStep;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: isDone || isActive
                ? AppColors.primary500
                : AppColors.scaffoldBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone || isActive
                  ? AppColors.primary500
                  : AppColors.grey50,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check_rounded,
                    size: 14.sp, color: AppColors.textDark)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.textDark
                          : AppColors.textGrey,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodySm.copyWith(
            fontSize: 10.sp,
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.textDark : AppColors.textGrey,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _stepConnector(int step, int currentStep) {
    final isDone = step < currentStep;
    return Expanded(
      child: Container(
        height: 1.5,
        margin: EdgeInsets.only(bottom: 20.h),
        color: isDone ? AppColors.primary500 : AppColors.grey50,
      ),
    );
  }

  // ── Payment step ─────────────────────────────────────────────────────────────

  Widget _buildPaymentStep(
      BuildContext context, WidgetRef ref, CheckoutState state) {
    final notifier = ref.read(checkoutProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // Pay from Wallet
          _buildPaymentOption(
            label: 'Pay from Wallet',
            method: PaymentMethod.wallet,
            state: state,
            notifier: notifier,
            child: state.selectedMethod == PaymentMethod.wallet
                ? _buildWalletCard()
                : null,
          ),
          SizedBox(height: 10.h),

          // Credit Card
          _buildPaymentOption(
            label: 'Credit Card',
            method: PaymentMethod.card,
            state: state,
            notifier: notifier,
            child: state.selectedMethod == PaymentMethod.card
                ? _buildCardList(context, state, notifier)
                : null,
          ),
          SizedBox(height: 10.h),

          // Bank Transfer
          _buildPaymentOption(
            label: 'Bank Transfer',
            method: PaymentMethod.bankTransfer,
            state: state,
            notifier: notifier,
          ),
          SizedBox(height: 16.h),

          // Info card
          _buildInfoCard(
            title: 'Choose a payment method',
            body:
                "You won't be charged until you review the order on the next page",
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String label,
    required PaymentMethod method,
    required CheckoutState state,
    required CheckoutNotifier notifier,
    Widget? child,
  }) {
    final isSelected = state.selectedMethod == method;
    return GestureDetector(
      onTap: () => notifier.selectMethod(method),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary500
                : AppColors.white200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _radioCircle(isSelected),
                SizedBox(width: 10.w),
                Text(
                  label,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14.sp,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            if (child != null) ...[
              SizedBox(height: 10.h),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _radioCircle(bool isSelected) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary500 : AppColors.grey500,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.secondary500,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Balance',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '₦50,500',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(
      BuildContext context, CheckoutState state, CheckoutNotifier notifier) {
    return Column(
      children: [
        ...state.savedCards.map((card) => _buildCardRow(card, state, notifier)),
        SizedBox(height: 4.h),
        GestureDetector(
          onTap: () => context.pushNamed(RouteNames.addCard),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 18.sp, color: AppColors.textDark),
                SizedBox(width: 8.w),
                Text(
                  'Add new card',
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardRow(
      SavedCard card, CheckoutState state, CheckoutNotifier notifier) {
    final isSelected = state.selectedCardId == card.id;
    final label = card.type == 'mastercard' ? 'Mastercard' : 'Visa';
    return GestureDetector(
      onTap: () => notifier.selectCard(card.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                  Text(
                    'xxxx xxxx xxxx ${card.lastFour}',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded,
                  size: 18.sp, color: AppColors.secondary500),
          ],
        ),
      ),
    );
  }

  // ── Review step ──────────────────────────────────────────────────────────────

  Widget _buildReviewStep(BuildContext context, WidgetRef ref,
      CheckoutState state, StashState stash) {
    final names = stash.items.map((i) => i.name).toList();
    final preview = names.length <= 2
        ? names.join(', ')
        : '${names.take(2).join(', ')}, ${names[2]}...';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your Order',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.white200),
            ),
            child: Column(
              children: [
                // Items summary
                _reviewRow(
                  leading: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stash.items.length} items',
                        style: AppTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        preview,
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 22.sp, color: AppColors.textGrey),
                ),
                _reviewDivider(),

                // Pickup / address
                _reviewRow(
                  leading: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup',
                        style: AppTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        stash.deliveryAddress,
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.edit_outlined,
                      size: 18.sp, color: AppColors.textGrey),
                ),
                _reviewDivider(),

                // Money breakdown
                Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Money Breakdown',
                        style: AppTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      _breakdownRow('Items Total:', stash.subtotal),
                      SizedBox(height: 4.h),
                      _breakdownRow('Delivery Fee:', stash.deliveryFee),
                      SizedBox(height: 4.h),
                      _breakdownRow('Service Fee (5%):', stash.serviceFee),
                      SizedBox(height: 4.h),
                      _breakdownRow('Grand Total:', stash.grandTotal,
                          bold: true),
                    ],
                  ),
                ),
                _reviewDivider(),

                // Payment method
                _reviewRow(
                  leading: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: AppTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        _paymentLabel(state),
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.edit_outlined,
                      size: 18.sp, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow({required Widget leading, required Widget trailing}) {
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Row(
        children: [
          Expanded(child: leading),
          trailing,
        ],
      ),
    );
  }

  Widget _reviewDivider() =>
      Divider(height: 1, thickness: 1, color: AppColors.white200);

  Widget _breakdownRow(String label, double amount, {bool bold = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyle.bodySm.copyWith(
            fontSize: 12.sp,
            color: AppColors.textGrey,
          ),
        ),
        const Spacer(),
        Text(
          _naira(amount),
          style: AppTextStyle.bodySm.copyWith(
            fontSize: 12.sp,
            color: AppColors.textDark,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _paymentLabel(CheckoutState state) {
    return switch (state.selectedMethod) {
      PaymentMethod.wallet => 'Your Wallet',
      PaymentMethod.card => state.selectedCard != null
          ? '${state.selectedCard!.type == 'mastercard' ? 'Mastercard' : 'Visa'} ****${state.selectedCard!.lastFour}'
          : 'Credit Card',
      PaymentMethod.bankTransfer => 'Bank Transfer',
      null => '—',
    };
  }

  // ── Info card ────────────────────────────────────────────────────────────────

  Widget _buildInfoCard({required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyle.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            body,
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, WidgetRef ref,
      CheckoutState state, StashState stash) {
    final notifier = ref.read(checkoutProvider.notifier);
    final isPayment = state.step == CheckoutStep.payment;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.white200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 13.sp,
                ),
              ),
              Text(
                _naira(stash.grandTotal),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isPayment && !state.canProceed) || state.isProcessing
                  ? null
                  : () async {
                      if (isPayment) {
                        notifier.proceedToReview();
                      } else {
                        final url = await notifier.pay();
                        if (!context.mounted) return;
                        if (url != null) {
                          final reference = await context.pushNamed<String?>(
                            RouteNames.paystackWebview,
                            extra: url,
                          );
                          if (reference != null && context.mounted) {
                            ref
                                .read(paymentRemoteDatasourceProvider)
                                .verifyPayment(reference)
                                .ignore();
                            _showSuccessSheet(context, ref);
                          }
                        } else if (ref.read(checkoutProvider).isSuccess) {
                          _showSuccessSheet(context, ref);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary500,
                disabledBackgroundColor: AppColors.buttonDisabled,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r)),
                elevation: 0,
              ),
              child: state.isProcessing
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isPayment ? 'Continue' : 'Pay Now',
                      style: AppTextStyle.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment success sheet ────────────────────────────────────────────────────

  void _showSuccessSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSuccessSheet(
        onBackToHome: () {
          ref.read(checkoutProvider.notifier).reset();
          context.goNamed(RouteNames.home);
        },
      ),
    );
  }

  String _naira(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final result = StringBuffer('₦');
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write(',');
      result.write(parts[i]);
    }
    return result.toString();
  }
}

// ── Payment Success Sheet ─────────────────────────────────────────────────────

class _PaymentSuccessSheet extends StatelessWidget {
  final VoidCallback onBackToHome;
  const _PaymentSuccessSheet({required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.fromLTRB(32.w, 32.h, 32.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glow + icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110.w,
                height: 110.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary500.withValues(alpha: 0.18),
                ),
              ),
              Container(
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary500,
                ),
                child: Icon(
                  Icons.payments_outlined,
                  color: AppColors.white,
                  size: 34.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'Payment made!',
            style: AppTextStyle.headingSm.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'The seller will receive the money when delivery\nhas been confirmed',
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
              onPressed: onBackToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary500,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r)),
                elevation: 0,
              ),
              child: Text(
                'Back to home',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
