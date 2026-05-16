import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class WalletCard extends ConsumerWidget {
  const WalletCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider);
    final notifier = ref.read(walletProvider.notifier);

    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.wallet),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.secondary500,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 8),
              blurRadius: 10,
              spreadRadius: -6,
              color: AppColors.black.withValues(alpha: 0.1),
            ),
            BoxShadow(
              offset: const Offset(0, 20),
              blurRadius: 25,
              spreadRadius: -5,
              color: AppColors.black.withValues(alpha: 0.1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Wallet Balance',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.grey50,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => notifier.toggleBalanceVisibility(),
                      child: Icon(
                        state.isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.isBalanceVisible
                      ? '₦${state.balance.toStringAsFixed(0)}'
                      : '₦ ****',
                  style: AppTextStyle.headingMd.copyWith(
                    fontSize: 28.sp,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            Container(
              height: 45.h,
              width: 45.w,
              decoration: const BoxDecoration(
                color: AppColors.primary500,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                  Icons.chevron_right, color: AppColors.black, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
