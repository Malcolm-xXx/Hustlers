import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_detail_provider.dart';

class ProductDetailView extends ConsumerWidget {
  final ProductEntity product;

  const ProductDetailView({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(productQuantityProvider(product.id));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image with overlay controls
                  _buildHeroImage(context),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),

                        // Product name
                        Text(
                          product.title,
                          style: AppTextStyle.headingMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 22.sp,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // Price row
                        _buildPriceRow(),

                        SizedBox(height: 20.h),

                        // Divider
                        Divider(height: 1, color: AppColors.grey50),

                        SizedBox(height: 16.h),

                        // Store info
                        _buildStoreInfo(),

                        SizedBox(height: 16.h),

                        Divider(height: 1, color: AppColors.grey50),

                        SizedBox(height: 20.h),

                        // Product Description
                        Text(
                          'Product Description',
                          style: AppTextStyle.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          product.description,
                          style: AppTextStyle.bodyMd.copyWith(
                            color: AppColors.textGrey,
                            height: 1.6,
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Shelf life
                        Text(
                          'Shelf life',
                          style: AppTextStyle.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          product.shelfLife ?? '',
                          style: AppTextStyle.bodyMd.copyWith(
                            color: AppColors.textGrey,
                            height: 1.6,
                          ),
                        ),

                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          _buildBottomBar(context, ref, quantity),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return Stack(
      children: [
        // Product image
        Container(
          width: double.infinity,
          height: 300.h,
          decoration: BoxDecoration(
            color: AppColors.grey50,
            image: DecorationImage(
              image: NetworkImage(product.imageUrl ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Gradient overlay at top for better icon visibility
        Container(
          width: double.infinity,
          height: 120.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Top bar with back, share, bookmark
        Positioned(
          top: MediaQuery.of(context).padding.top + 8.h,
          left: 16.w,
          right: 16.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => context.pop(),
              ),
              Row(
                children: [
                  _buildCircleButton(
                    icon: Icons.share_outlined,
                    onTap: () {},
                  ),
                  SizedBox(width: 8.w),
                  _buildCircleButton(
                    icon: Icons.bookmark_border,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),

        // Badge
        if (product.badge != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60.h,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                product.badge!,
                style: AppTextStyle.bodySm.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),

        // Discount percentage badge
        if (product.hasDiscount)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60.h,
            left: 16.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.logOutRed,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '-${product.discountPercentage.toStringAsFixed(0)}%',
                style: AppTextStyle.bodySm.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.h,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18.sp, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Current price
        Text(
          '\u20A6${product.price.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary600,
          ),
        ),
        SizedBox(width: 4.w),
        // Unit
        Text(
          '/${product.unit}',
          style: AppTextStyle.bodySm.copyWith(
            color: AppColors.primary600,
            fontSize: 13.sp,
          ),
        ),
        // Original price (strikethrough) if discounted
        if (product.hasDiscount) ...[
          SizedBox(width: 10.w),
          Text(
            '\u20A6${product.originalPrice!.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textGrey,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textGrey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStoreInfo() {
    return Row(
      children: [
        // Store avatar
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.store_outlined,
            size: 20.sp,
            color: AppColors.primary600,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.seller?.name ?? 'Unknown Store',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(Icons.star, size: 14.sp, color: AppColors.starYellow),
                  SizedBox(width: 3.w),
                  Text(
                    product.rating.toString(),
                    style: AppTextStyle.bodySm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                      fontSize: 12.sp,
                    ),
                  ),
                  // Seller verification badge removed as it's not in SellerEntity
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, int quantity) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: AppColors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (quantity > 1) {
                      ref
                          .read(productQuantityProvider(product.id).notifier)
                          .state = quantity - 1;
                    }
                  },
                  enabled: quantity > 1,
                ),
                SizedBox(
                  width: 40.w,
                  child: Center(
                    child: Text(
                      quantity.toString(),
                      style: AppTextStyle.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  onTap: () {
                    ref
                        .read(productQuantityProvider(product.id).notifier)
                        .state = quantity + 1;
                  },
                  enabled: true,
                ),
              ],
            ),
          ),

          SizedBox(width: 16.w),

          // Add to Stash button
          Expanded(
            child: AppPrimaryButton(
              text: 'Add to Stash',
              onPressed: () {
                // TODO: Add to stash functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Added $quantity x ${product.title} to stash'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: AppColors.secondary500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40.w,
        height: 44.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: enabled ? AppColors.textDark : AppColors.grey500,
        ),
      ),
    );
  }
}
