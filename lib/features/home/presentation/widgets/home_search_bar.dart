import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hustlers/core/constants/app_assets.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../search/presentation/views/filter_view.dart';
import '../../../search/presentation/views/search_view.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search,
                      color: Color(0xFFB8B8B8),

                      size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchView(),
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Search food item, hustler, loc...',
                        hintStyle: AppTextStyle.bodyMd.copyWith(
                          color: const Color(0xFFB8B8B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ), // Center text vertically
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FilterView()),
              );
            },
            child: Container(
              height: 52.h,
              width: 52.w,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1A28), // Dark color
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(AppAssets.filter),
            ),
          ),
        ],
      ),
    );
  }
}
