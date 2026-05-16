import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_style.dart';

/// A beautiful branded loading card with a dual-ring spinner.
///
/// Drop-in usage inside a [LoadingOverlay] or as a standalone widget.
class AppLoader extends StatefulWidget {
  final String? message;

  const AppLoader({super.key, this.message});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with TickerProviderStateMixin {
  late final AnimationController _outerController;
  late final AnimationController _innerController;

  @override
  void initState() {
    super.initState();

    // Outer ring — slow clockwise
    _outerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Inner ring — fast counter-clockwise
    _innerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _outerController.dispose();
    _innerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary500.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spinner
          SizedBox(
            width: 56.r,
            height: 56.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring — slow, light
                RotationTransition(
                  turns: _outerController,
                  child: SizedBox(
                    width: 56.r,
                    height: 56.r,
                    child: CircularProgressIndicator(
                      value: 0.78,
                      strokeWidth: 3.r,
                      strokeCap: StrokeCap.round,
                      color: AppColors.primary500.withOpacity(0.35),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),

                // Inner ring — fast, solid yellow, counter-clockwise
                RotationTransition(
                  turns: Tween(begin: 1.0, end: 0.0)
                      .animate(_innerController),
                  child: SizedBox(
                    width: 36.r,
                    height: 36.r,
                    child: CircularProgressIndicator(
                      value: 0.65,
                      strokeWidth: 3.5.r,
                      strokeCap: StrokeCap.round,
                      color: AppColors.primary500,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),

                // Center dot
                Container(
                  width: 7.r,
                  height: 7.r,
                  decoration: const BoxDecoration(
                    color: AppColors.primary500,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Message
          Text(
            widget.message ?? 'Please wait...',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 180.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1.0, 1.0),
          duration: 220.ms,
          curve: Curves.easeOutBack,
        );
  }
}
