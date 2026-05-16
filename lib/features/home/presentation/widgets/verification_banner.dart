import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hustlers/core/constants/app_assets.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../verification/presentation/providers/verification_provider.dart';

class VerificationBanner extends ConsumerWidget {
  const VerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(verificationStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status['status'] == 'verified') return const SizedBox.shrink();
        
        return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
            color: AppColors.black.withOpacity(0.1)
          ),
          BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 3,
              spreadRadius: 0,
              color: AppColors.black.withOpacity(0.1)
          )
        ]
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Earning on Hustler',
                style: AppTextStyle.headingSm.copyWith(
                  color: AppColors.black,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verify your ID to start selling today',
                style: AppTextStyle.bodySm.copyWith(
                  color: Color(0xff6A7282),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.pushNamed(RouteNames.idVerification),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary500,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(AppAssets.shield),
                      const SizedBox(width: 8),
                      Text(
                        'Get Verified',
                        style: AppTextStyle.bodySm.copyWith(
                          color: const Color(0xFF0F1B2A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {},
              child: const Icon(Icons.close, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
