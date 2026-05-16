import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import 'app_loader.dart';

/// Wraps any screen widget and shows a full-screen loading overlay
/// when [isLoading] is true.
///
/// Interaction with the underlying screen is blocked while loading.
///
/// ```dart
/// LoadingOverlay(
///   isLoading: state.isLoading,
///   child: Scaffold(...),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        // Barrier — blocks all gestures when loading
        IgnorePointer(
          ignoring: !isLoading,
          child: AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _Barrier(message: message),
          ),
        ),
      ],
    );
  }
}

class _Barrier extends StatelessWidget {
  final String? message;
  const _Barrier({this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.secondary500.withOpacity(0.55),
      ),
      child: SizedBox.expand(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: AppLoader(message: message),
          ),
        ),
      ),
    );
  }
}
