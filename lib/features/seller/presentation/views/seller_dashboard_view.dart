import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';

class SellerDashboardView extends StatelessWidget {
  final Widget child;

  const SellerDashboardView({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RoutePaths.sellerHome)) return 0;
    if (location.startsWith(RoutePaths.sellerOrders)) return 1;
    if (location.startsWith(RoutePaths.sellerStore)) return 2;
    if (location.startsWith(RoutePaths.sellerInsights)) return 3;
    if (location.startsWith(RoutePaths.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(RouteNames.sellerHome);
      case 1:
        context.goNamed(RouteNames.sellerOrders);
      case 2:
        context.goNamed(RouteNames.sellerStore);
      case 3:
        context.goNamed(RouteNames.sellerInsights);
      case 4:
        context.goNamed(RouteNames.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: child,
      bottomNavigationBar: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: const Color(0xFF1B1A28),
          unselectedItemColor: AppColors.grey400,
          selectedLabelStyle: AppTextStyle.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 10.sp,
            color: const Color(0xFF1B1A28),
          ),
          unselectedLabelStyle: AppTextStyle.bodySm.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 10.sp,
            color: AppColors.grey400,
          ),
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 24,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  selectedIndex == 1
                      ? Icons.receipt_long
                      : Icons.receipt_long_outlined,
                  size: 24,
                ),
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  selectedIndex == 2
                      ? Icons.storefront
                      : Icons.storefront_outlined,
                  size: 24,
                ),
              ),
              label: 'My Store',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  selectedIndex == 3
                      ? Icons.insights
                      : Icons.insights_outlined,
                  size: 24,
                ),
              ),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  selectedIndex == 4 ? Icons.person : Icons.person_outline,
                  size: 24,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
