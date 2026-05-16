import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../providers/splash_provider.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);

    if (hasCompletedOnboarding) {
      context.goNamed(RouteNames.onboarding);
    } else {
      context.goNamed(RouteNames.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child:
            Text(
                  'Hustler',
                  style: AppTextStyle.displayLg.copyWith(fontSize: 80.sp),
                )
                .animate()
                .fade(duration: 600.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  delay: 200.ms,
                  curve: Curves.easeOutBack,
                ),
      ),
    );
  }
}
