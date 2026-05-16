import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../payments/data/datasources/payment_remote_datasource.dart';
import '../../data/models/wallet_models.dart';
import '../providers/topup_provider.dart';
import '../providers/wallet_provider.dart';
import 'topup_sheet.dart';
import 'withdraw_sheet.dart';

class MyWalletView extends ConsumerWidget {
  const MyWalletView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  SliverToBoxAdapter(child: _buildBalanceCard(context, ref, state)),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  SliverToBoxAdapter(child: _buildSavedMethods(context, state)),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  SliverToBoxAdapter(child: _buildAvailableProducts(context)),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  SliverToBoxAdapter(child: _buildTransactionHistoryHeader(context, ref, state)),
                  SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                  SliverToBoxAdapter(child: _buildFilterTabs(ref, state)),
                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  ..._buildTransactionList(state),
                  SliverToBoxAdapter(child: SizedBox(height: 32.h)),
                ],
              ),
      ),
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
            'My Wallet',
            style: AppTextStyle.headingSm.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6600),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'SQUAD API',
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, WidgetRef ref, WalletState state) {
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
                Container(
                  width: 22.r,
                  height: 22.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary500.withValues(alpha: 0.5),
                        width: 1),
                  ),
                  child: Icon(
                    Icons.monetization_on_outlined,
                    size: 12.sp,
                    color: AppColors.primary500,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'TOTAL BALANCE',
                  style: AppTextStyle.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11.sp,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      ref.read(walletProvider.notifier).toggleBalanceVisibility(),
                  child: Icon(
                    state.isBalanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            state.isBalanceVisible
                ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₦',
                          style: AppTextStyle.bodyMd.copyWith(
                            color: AppColors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: _formatInt(state.balance),
                          style: AppTextStyle.headingSm.copyWith(
                            color: AppColors.white,
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w800,
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
                  )
                : Text(
                    '₦ ••••••',
                    style: AppTextStyle.headingSm.copyWith(
                      color: AppColors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            SizedBox(height: 4.h),
            Text(
              'Available balance',
              style: AppTextStyle.bodySm.copyWith(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
                height: 1),
            SizedBox(height: 14.h),
            Row(
              children: [
                _MoneyStatItem(
                  label: 'Money In',
                  amount: '+₦${_formatInt(state.moneyIn)}',
                  amountColor: const Color(0xFF34C759),
                  iconColor: const Color(0xFF34C759),
                  icon: Icons.arrow_outward,
                ),
                SizedBox(width: 16.w),
                _MoneyStatItem(
                  label: 'Money Out',
                  amount: '-₦${_formatInt(state.moneyOut)}',
                  amountColor: const Color(0xFFFF3B30),
                  iconColor: const Color(0xFFFF3B30),
                  icon: Icons.south_east,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.show_chart,
                        color: Colors.white.withValues(alpha: 0.5), size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'This Week',
                      style: AppTextStyle.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _CardActionButton(
                    icon: Icons.add,
                    label: 'Top Up',
                    iconBg: AppColors.primary500,
                    iconColor: AppColors.textDark,
                    onTap: () => _openTopUp(context, ref),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _CardActionButton(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Withdraw',
                    iconBg: Colors.white.withValues(alpha: 0.15),
                    iconColor: AppColors.white,
                    onTap: () => _openWithdraw(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTopUp(BuildContext context, WidgetRef ref) async {
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TopUpSheet(),
    );
    if (url != null && context.mounted) {
      final reference = await context.pushNamed<String?>(
        RouteNames.paystackWebview,
        extra: url,
      );
      if (reference != null && context.mounted) {
        // Notify backend — non-fatal if it fails
        ref
            .read(paymentRemoteDatasourceProvider)
            .verifyPayment(reference)
            .ignore();
        ref.read(topUpProvider.notifier).handlePaystackSuccess();
      }
    }
  }

  void _openWithdraw(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WithdrawSheet(),
    );
  }

  Widget _buildSavedMethods(BuildContext context, WalletState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Saved Methods',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  '+ Add New',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...state.savedCards.map((card) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _SavedCardTile(card: card),
              )),
          ...state.linkedAccounts.map((account) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _BankAccountTile(account: account),
              )),
        ],
      ),
    );
  }

  Widget _buildAvailableProducts(BuildContext context) {
    const products = [
      _ProductItem(
        icon: Icons.currency_exchange_outlined,
        title: 'Micro Loan - ₦25,000',
        subtitle:
            'Qualified from your hustle score. 0% first loan. Repay from earnings.',
        routeName: RouteNames.microLoan,
      ),
      _ProductItem(
        icon: Icons.savings_outlined,
        title: 'Hustle Savings',
        subtitle:
            'Auto-save 10% of every payout. Earn 8% annual interest.',
        routeName: RouteNames.hustleSavings,
      ),
      _ProductItem(
        icon: Icons.shield_outlined,
        title: 'Gig Insurance',
        subtitle:
            'Accident and income protection from ₦500/month.',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Products',
            style: AppTextStyle.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 12.h),
          ...products.map(
            (p) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: GestureDetector(
                onTap: p.routeName != null
                    ? () => context.pushNamed(p.routeName!)
                    : null,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: AppColors.grey500.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(p.icon,
                            size: 20.sp, color: AppColors.primary600),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: AppTextStyle.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              p.subtitle,
                              style: AppTextStyle.bodySm.copyWith(
                                color: AppColors.textGrey,
                                fontSize: 12.sp,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.chevron_right,
                          size: 20.sp, color: AppColors.grey500),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistoryHeader(
      BuildContext context, WidgetRef ref, WalletState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Text(
            'Transaction History',
            style: AppTextStyle.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Row(
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(WidgetRef ref, WalletState state) {
    const filters = [
      (TransactionFilter.all, 'All'),
      (TransactionFilter.orders, 'Orders'),
      (TransactionFilter.topUps, 'Top Ups'),
      (TransactionFilter.withdrawals, 'Withdrawals'),
    ];

    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final (filter, label) = filters[i];
          final selected = state.activeFilter == filter;
          return GestureDetector(
            onTap: () => ref.read(walletProvider.notifier).setFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: selected ? AppColors.secondary500 : AppColors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected
                      ? AppColors.secondary500
                      : AppColors.grey500.withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyle.bodySm.copyWith(
                    color: selected ? AppColors.white : AppColors.textGrey,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildTransactionList(WalletState state) {
    final grouped = <String, List<WalletTransaction>>{};
    for (final tx in state.filteredTransactions) {
      grouped.putIfAbsent(tx.date, () => []).add(tx);
    }

    final result = <Widget>[];
    grouped.forEach((date, txs) {
      result.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
          child: Text(
            date,
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 11.sp,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ));
      for (final tx in txs) {
        result.add(SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 2.h),
            child: _TransactionTile(transaction: tx),
          ),
        ));
      }
    });

    if (grouped.isEmpty) {
      result.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Center(
            child: Text(
              'No transactions yet',
              style: AppTextStyle.bodyMd.copyWith(color: AppColors.textGrey),
            ),
          ),
        ),
      ));
    }

    return result;
  }

  String _formatInt(double v) {
    final n = v.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

// ── Data class for Available Products ────────────────────────────────────────

class _ProductItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? routeName;

  const _ProductItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.routeName,
  });
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _MoneyStatItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color amountColor;
  final Color iconColor;
  final IconData icon;

  const _MoneyStatItem({
    required this.label,
    required this.amount,
    required this.amountColor,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26.r,
          height: 26.r,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 13.sp),
        ),
        SizedBox(width: 7.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              amount,
              style: AppTextStyle.bodySm.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
            ),
            Text(
              label,
              style: AppTextStyle.bodySm.copyWith(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 16.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  final WalletSavedCard card;

  const _SavedCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: card.isDefault
              ? AppColors.primary500
              : AppColors.grey500.withValues(alpha: 0.3),
          width: card.isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'VISA',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1F71),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•••• •••• •••• ${card.lastFour}',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: AppColors.textDark,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Expires ${card.expires}',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (card.isDefault)
            Container(
              width: 10.r,
              height: 10.r,
              decoration: const BoxDecoration(
                color: AppColors.primary500,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _BankAccountTile extends StatelessWidget {
  final LinkedBankAccount account;

  const _BankAccountTile({required this.account});

  static const _bankColors = {
    'GTBank': Color(0xFFDD3300),
    'Access Bank': Color(0xFF006633),
    'Zenith Bank': Color(0xFF8B0000),
    'First Bank': Color(0xFF003580),
  };

  @override
  Widget build(BuildContext context) {
    final brandColor =
        _bankColors[account.bankName] ?? AppColors.primary600;
    final initials = account.bankName.length >= 2
        ? account.bankName.substring(0, 2).toUpperCase()
        : account.bankName[0].toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border:
            Border.all(color: AppColors.grey500.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.bankName,
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '•••• ${account.lastFour}',
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
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  (Color, Color, IconData) get _typeStyle {
    return switch (transaction.type) {
      TransactionType.order => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.shopping_cart_outlined,
        ),
      TransactionType.topUp => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.arrow_downward_rounded,
        ),
      TransactionType.withdrawal => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          Icons.arrow_upward_rounded,
        ),
      TransactionType.refund => (
          const Color(0xFFE8EAF6),
          const Color(0xFF283593),
          Icons.replay_rounded,
        ),
    };
  }

  (IconData, Color, String) get _statusStyle {
    return switch (transaction.status) {
      TransactionStatus.completed => (
          Icons.check_circle_outline,
          const Color(0xFF34C759),
          'Completed',
        ),
      TransactionStatus.processing => (
          Icons.access_time_outlined,
          const Color(0xFFFF9500),
          'Pending',
        ),
      TransactionStatus.failed => (
          Icons.cancel_outlined,
          const Color(0xFFFF3B30),
          'Failed',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final (iconBg, iconColor, icon) = _typeStyle;
    final (statusIcon, statusColor, statusLabel) = _statusStyle;
    final isCompleted = transaction.status == TransactionStatus.completed;

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
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text(
                      '$statusLabel  •  ${transaction.time}',
                      style: AppTextStyle.bodySm.copyWith(
                        color: isCompleted
                            ? AppColors.textGrey
                            : statusColor,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCredit
                    ? '+₦${_fmt(transaction.amount)}'
                    : '-₦${_fmt(transaction.amount.abs())}',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: isCredit
                      ? const Color(0xFF34C759)
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(width: 4.w),
          Icon(Icons.chevron_right, color: AppColors.grey500, size: 18.sp),
        ],
      ),
    );
  }

  String _fmt(double v) {
    return v.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
