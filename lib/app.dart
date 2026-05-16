import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_text_style.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/route_names.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';

class HustlersApp extends ConsumerWidget {
  const HustlersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      final justExpired = next.sessionExpired && !(prev?.sessionExpired ?? false);
      if (!justExpired) return;

      final navContext = appRouter.routerDelegate.navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;

      showDialog<void>(
        context: navContext,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text('Session Expired', style: AppTextStyle.headingSm),
          content: Text(
            'Your session has expired. Please log in again to continue.',
            style: AppTextStyle.bodyMd,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(navContext).pop();
                ref.read(authStateProvider.notifier).clearSessionExpired();
                appRouter.go(RoutePaths.signIn);
              },
              child: Text(
                'Log in again',
                style: AppTextStyle.labelMd.copyWith(color: AppColors.primary500),
              ),
            ),
          ],
        ),
      );
    });

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary500,
              primary: AppColors.primary500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            textTheme: TextTheme(
              displayLarge: AppTextStyle.displayLg,
              headlineLarge: AppTextStyle.headingLg,
              headlineMedium: AppTextStyle.headingMd,
              headlineSmall: AppTextStyle.headingSm,
              bodyLarge: AppTextStyle.bodyLg,
              bodyMedium: AppTextStyle.bodyMd,
              bodySmall: AppTextStyle.bodySm,
              labelLarge: AppTextStyle.labelLg,
              labelMedium: AppTextStyle.labelMd,
              labelSmall: AppTextStyle.labelSm,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkButton,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                textStyle: AppTextStyle.labelLg.copyWith(fontFamily: 'Poppins'),
                minimumSize: Size(0, 56.h),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textDark,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                textStyle: AppTextStyle.labelMd.copyWith(fontFamily: 'Poppins'),
              ),
            ),
          ),
          routerConfig: appRouter,
        );
      },
    );
  }
}
