import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';

class SelectLocationView extends StatefulWidget {
  const SelectLocationView({super.key});

  @override
  State<SelectLocationView> createState() => _SelectLocationViewState();
}

class _SelectLocationViewState extends State<SelectLocationView> {
  final _searchController = TextEditingController();

  final _recentLocations = ['Odo-Ona Market', 'Central Market'];

  final _popularLocations = [
    _LocationItem(name: 'Odo-Ona Market', area: '', rating: 4.5),
    _LocationItem(name: 'Central Market, Bodija', area: '', rating: 4.3),
    _LocationItem(name: 'Dugbe Market', area: '', rating: 4.1),
    _LocationItem(
        name: 'Spar Supermarket, Lekki', area: '', rating: 4.7),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20.sp, color: AppColors.textDark),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Select Location',
                    style: AppTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.close,
                        size: 22.sp, color: AppColors.textDark),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                controller: _searchController,
                style: AppTextStyle.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Search markets, stores...',
                  hintStyle: AppTextStyle.hint,
                  prefixIcon: Icon(Icons.search,
                      size: 20.sp, color: AppColors.textGrey),
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Use Current Location
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: GestureDetector(
                onTap: () => context.pop('Current Location'),
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.my_location,
                            size: 20.sp, color: const Color(0xFF1976D2)),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Current Location',
                            style: AppTextStyle.labelMd.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1976D2),
                            ),
                          ),
                          Text(
                            'Get groceries from stores nearby',
                            style: AppTextStyle.bodySm.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Recent Locations
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'RECENT LOCATIONS',
                style: AppTextStyle.bodySm.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Wrap(
                spacing: 8.w,
                children: _recentLocations.map((loc) {
                  return GestureDetector(
                    onTap: () => context.pop(loc),
                    child: Chip(
                      label: Text(
                        loc,
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                      backgroundColor: AppColors.scaffoldBackground,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 24.h),

            // Popular Locations
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'POPULAR LOCATIONS',
                style: AppTextStyle.bodySm.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 8.h),

            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: _popularLocations.length,
                separatorBuilder: (_, __) => Divider(
                  color: AppColors.grey50,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final loc = _popularLocations[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.pop(loc.name),
                    leading: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.location_on_outlined,
                          size: 20.sp, color: AppColors.primary500),
                    ),
                    title: Text(
                      loc.name,
                      style: AppTextStyle.labelMd.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star,
                            size: 14.sp, color: AppColors.primary500),
                        SizedBox(width: 2.w),
                        Text(
                          loc.rating.toString(),
                          style: AppTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationItem {
  final String name;
  final String area;
  final double rating;

  const _LocationItem({
    required this.name,
    required this.area,
    required this.rating,
  });
}
