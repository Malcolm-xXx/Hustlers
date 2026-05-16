import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hustlers/core/constants/app_text_style.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_widget.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final isFirstPage = state.currentPage == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 18.5.h),
                      child: Text(
                        'Hustler',
                        style: AppTextStyle.displayLg.copyWith(
                          fontSize: 30.sp,
                          color: AppColors.primary500,
                        ),
                      ),
                    ),

                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    //   child: Align(
                    //     alignment: Alignment.centerLeft,
                    //     child: isFirstPage
                    //         ? const SizedBox(height: 48)
                    //         : IconButton(
                    //             onPressed: _goBack,
                    //             icon: const Icon(
                    //               Icons.arrow_back,
                    //               color: AppColors.textDark,
                    //               size: 24,
                    //             ),
                    //           ),
                    //   ),
                    // ),
                    Flexible(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: state.pages.length,
                        onPageChanged: notifier.setPage,
                        itemBuilder: (context, index) {
                          final page = state.pages[index];
                          return OnboardingPageWidget(
                            titleSegments: page.titleSegments,
                            description: page.description,
                            asset: page.asset,
                            height: page.height,
                            width: page.width,
                            radius: page.radius,
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          state.pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            height: 12.h,
                            width: state.currentPage == index ? 52.w : 12.w,
                            decoration: BoxDecoration(
                              color: state.currentPage == index
                                  ? AppColors.darkButton
                                  : AppColors.dotInactive,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AppPrimaryButton(
                        textStyle: AppTextStyle.bodyLg.copyWith(
                          color: AppColors.white,
                        ),
                        text: 'Sign In',
                        onPressed: () {
                          notifier.navigateToSignIn(context);
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10.h,
                      ),
                      child: AppPrimaryButton(
                        backgroundColor: AppColors.secondary500.withOpacity(0.05),
                        foregroundColor: AppColors.secondary500,
                        borderRadius: 100.r,
                        textStyle: AppTextStyle.bodyLg.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        text: 'Create an account',
                        onPressed: () {
                          notifier.completeOnboarding(context);

                          // if (state.isLastPage) {
                          // } else {
                          //   _pageController.nextPage(
                          //     duration: const Duration(milliseconds: 300),
                          //     curve: Curves.easeInOut,
                          //   );
                          // }
                        },
                      ),
                    ),

                    // if (!state.isLastPage)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 4, bottom: 16),
                    //     child: AppTextButton(
                    //       textStyle: AppTextStyle.bodyLg.copyWith(
                    //         color: AppColors.secondary500
                    //       ),
                    //       text: 'Skip',
                    //       onPressed: () => notifier.completeOnboarding(context),
                    //     ),
                    //   )
                    // else
                    //   const SizedBox(height: 48),
                  ]
                  .animate(interval: 100.ms)
                  .fade(duration: 500.ms)
                  .slideY(
                    begin: 0.1,
                    duration: 500.ms,
                    curve: Curves.easeOutQuad,
                  ),
        ),
      ),
    );
  }
}
