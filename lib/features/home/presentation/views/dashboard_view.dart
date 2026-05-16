import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hustlers/core/constants/app_colors.dart';
import 'package:hustlers/core/constants/app_text_style.dart';
import 'package:hustlers/core/navigation/route_names.dart';

import '../widgets/app_drawer.dart';

class DashboardView extends StatefulWidget {
  final Widget child;

  const DashboardView({super.key, required this.child});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  void _onItemTapped(int index, BuildContext context) {
    if (index == 2) return; // FAB index

    switch (index) {
      case 0:
        context.goNamed(RouteNames.home);
        break;
      case 1:
        context.goNamed(RouteNames.stash);
        break;
      case 3:
        context.goNamed(RouteNames.myOrders);
        break;
      case 4:
        context.goNamed(RouteNames.profile);
        break;
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RoutePaths.home)) return 0;
    if (location.startsWith(RoutePaths.stash)) return 1;
    if (location.startsWith(RoutePaths.myOrders)) return 3;
    if (location.startsWith(RoutePaths.profile)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      drawer: const AppDrawer(),
      body: widget.child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: FloatingActionButton(
          onPressed: () => context.pushNamed(RouteNames.createHustleList),
          backgroundColor: const Color(0xFF1B1A28),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: AppColors.white, size: 28),
        ),
      ),
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
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(
                  selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 24,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(
                  selectedIndex == 1
                      ? Icons.shopping_bag
                      : Icons.shopping_bag_outlined,
                  size: 24,
                ),
              ),
              label: 'Stash',
            ),
            const BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Icon(
                  selectedIndex == 3 ? Icons.watch_later : Icons.access_time,
                  size: 24,
                ),
              ),
              label: 'My Orders',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
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
