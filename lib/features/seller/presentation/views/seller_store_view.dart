import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../data/models/store_item_model.dart';
import '../providers/seller_provider.dart';

class SellerStoreView extends ConsumerWidget {
  const SellerStoreView({super.key});

  static const _filters = ['All', 'Grains', 'Tubers', 'Drinks', 'Proteins'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerProvider);
    final notifier = ref.read(sellerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Hero banner
                SliverToBoxAdapter(child: _buildHeroBanner(context, state)),

                // Stats row
                SliverToBoxAdapter(child: _buildStatsRow(state)),

                // Launch Promotion
                SliverToBoxAdapter(child: _buildPromotionCard()),

                // Drafts
                if (state.drafts.isNotEmpty)
                  SliverToBoxAdapter(
                      child: _buildDraftsSection(state, notifier)),

                // My Items header + filters
                SliverToBoxAdapter(
                    child: _buildItemsHeader(state, notifier)),

                // Items list or empty state
                if (state.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.storeItems.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState(notifier, context))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final items = state.filteredItems;
                        if (index >= items.length) return null;
                        return _buildItemRow(
                            items[index], notifier, context);
                      },
                      childCount: state.filteredItems.length,
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              ],
            ),
          ),

          // Add new item button
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
            color: Colors.white,
            child: AppPrimaryButton(
              text: state.storeItems.isEmpty
                  ? 'Add Products'
                  : 'Add new item',
              onPressed: () => notifier.navigateToAddItem(context),
              backgroundColor: AppColors.secondary500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, SellerState state) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner image
        Container(
          width: double.infinity,
          height: 180.h,
          decoration: BoxDecoration(
            color: AppColors.grey50,
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=600',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Top icons
        Positioned(
          top: MediaQuery.of(context).padding.top + 8.h,
          left: 16.w,
          right: 16.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleIcon(Icons.arrow_back_ios_new, () {}),
              Row(
                children: [
                  _buildCircleIcon(Icons.search, () {}),
                  SizedBox(width: 8.w),
                  _buildCircleIcon(Icons.share_outlined, () {}),
                ],
              ),
            ],
          ),
        ),

        // Profile avatar
        Positioned(
          bottom: -40.h,
          left: 20.w,
          child: Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: AppColors.primary100,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1531123897727-8f129e1bf98a?q=80&w=250&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20.w,
                    height: 20.h,
                    decoration: const BoxDecoration(
                      color: AppColors.verifiedGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check,
                        size: 12.sp, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Add Item button
        Positioned(
          bottom: -20.h,
          right: 20.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary500,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16.sp, color: AppColors.textDark),
                SizedBox(width: 4.w),
                Text(
                  'Add Item',
                  style: AppTextStyle.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.h,
        decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18.sp, color: AppColors.white),
      ),
    );
  }

  Widget _buildStatsRow(SellerState state) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name + status
          Row(
            children: [
              Text(
                state.storeName,
                style: AppTextStyle.headingMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.h,
                      decoration: const BoxDecoration(
                        color: AppColors.verifiedGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Online',
                      style: AppTextStyle.bodySm.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.verifiedGreen,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.keyboard_arrow_down,
                  size: 18.sp, color: AppColors.verifiedGreen),
            ],
          ),

          SizedBox(height: 16.h),

          // Stats
          Row(
            children: [
              _buildStatItem(
                Icons.inventory_2_outlined,
                AppColors.primary500,
                'TOTAL ITEMS',
                '${state.activeItemCount} Active',
              ),
              SizedBox(width: 12.w),
              _buildStatItem(
                Icons.visibility_outlined,
                AppColors.verifiedGreen,
                'STORE VIEWS',
                '1.2k this week',
              ),
              SizedBox(width: 12.w),
              _buildStatItem(
                Icons.local_offer_outlined,
                AppColors.logOutRed,
                'ON SALE',
                '${state.onSaleCount} Items',
              ),
            ],
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, Color color, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18.sp, color: color),
            SizedBox(height: 6.h),
            Text(
              label,
              style: AppTextStyle.bodySm.copyWith(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: AppTextStyle.bodySm.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.campaign_outlined,
                size: 20.sp, color: AppColors.primary600),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Launch a Promotion',
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  'Boost sales with limited-time offers',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: 22.sp, color: AppColors.textGrey),
        ],
      ),
    );
  }

  Widget _buildDraftsSection(SellerState state, SellerNotifier notifier) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Drafts',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '(${state.drafts.length})',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'You have unfinished items',
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.textGrey,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ...state.drafts.map((draft) => Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.name,
                          style: AppTextStyle.labelMd.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '2 hours ago',
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        'Continue',
                        style: AppTextStyle.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildItemsHeader(SellerState state, SellerNotifier notifier) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Items',
                style: AppTextStyle.labelLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'See all',
                style: AppTextStyle.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = state.selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: GestureDetector(
                    onTap: () => notifier.setFilter(filter),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary100
                            : AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        filter,
                        style: AppTextStyle.bodySm.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary600
                              : AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SellerNotifier notifier, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(40.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Container(
            width: 100.w,
            height: 100.h,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48.sp,
              color: AppColors.grey500.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No Products Listed',
            style: AppTextStyle.headingSm.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "You haven't listed any products yet. Add your first product to start selling",
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          AppPrimaryButton(
            text: 'Add Products',
            onPressed: () => notifier.navigateToAddItem(context),
            backgroundColor: AppColors.primary500,
            foregroundColor: AppColors.textDark,
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
      StoreItemModel item, SellerNotifier notifier, BuildContext context) {
    return GestureDetector(
      onTap: () => notifier.navigateToEditItem(context, item),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: item.isOnSale
              ? AppColors.primary100.withOpacity(0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            // Sale badge + thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: 52.w,
                    height: 52.h,
                    color: AppColors.grey50,
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(item.imageUrl, fit: BoxFit.cover)
                        : Icon(Icons.image,
                            size: 24.sp, color: AppColors.grey500),
                  ),
                ),
                if (item.isOnSale)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.logOutRed,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10.r),
                          bottomRight: Radius.circular(6.r),
                        ),
                      ),
                      child: Text(
                        'SALE',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),

            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if (item.isOnSale) ...[
                        Text(
                          '\u20A6${item.salePrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '\u20A6${item.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.sp,
                            color: AppColors.textGrey,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textGrey,
                          ),
                        ),
                      ] else
                        Text(
                          '\u20A6 ${item.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      Text(
                        ' | ${item.unit}',
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stock status + edit
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.inStock ? 'In Stock' : 'Out of Stock',
                  style: AppTextStyle.bodySm.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color:
                        item.inStock ? AppColors.textDark : AppColors.logOutRed,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit',
                      style: AppTextStyle.bodySm.copyWith(
                        fontSize: 10.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () => notifier.toggleItemStock(item.id),
                      child: Container(
                        width: 36.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: item.inStock
                              ? AppColors.verifiedGreen
                              : AppColors.grey500,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: item.inStock
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 16.w,
                            height: 16.h,
                            margin: EdgeInsets.symmetric(horizontal: 2.w),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
