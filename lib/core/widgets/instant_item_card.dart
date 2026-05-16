import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hustlers/core/constants/app_colors.dart';
import 'package:hustlers/core/constants/app_text_style.dart';

class InstantItemCard extends StatelessWidget {
  final String name;
  final String price;
  final String badge;
  final Color badgeColor;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const InstantItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.badge,
    required this.badgeColor,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
              color: Color(0xFFE8EAEC)
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Color(0xFFE8EAEC)
                    ),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=300',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyle.bodySm.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              name,
              style: AppTextStyle.bodyMd.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              'Per Congo',
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.grey500,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Ifeanyi Bulk Store',
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.grey500,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(price,
                    style: AppTextStyle.headingSm.copyWith(fontSize: 16.sp)),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1A28),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.add,
                        color: AppColors.white, size: 16.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
