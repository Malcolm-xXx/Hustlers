import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../data/models/stash_models.dart';
import '../providers/stash_provider.dart';

class MyStashView extends ConsumerStatefulWidget {
  const MyStashView({super.key});

  @override
  ConsumerState<MyStashView> createState() => _MyStashViewState();
}

class _MyStashViewState extends ConsumerState<MyStashView> {
  int _tabIndex = 0;
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stashProvider);
    final notifier = ref.read(stashProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state, notifier),
            SizedBox(height: 12.h),
            _buildTabBar(),
            SizedBox(height: 8.h),
            Expanded(
              child: _tabIndex == 0
                  ? _buildItemsTab(state, notifier)
                  : _buildDeliveryTab(context, state, notifier),
            ),
            _buildBottomBar(context, state),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, StashState state, StashNotifier notifier) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_ios_new,
                size: 18.sp, color: AppColors.textDark),
          ),
          SizedBox(width: 10.w),
          Text(
            'My Stash',
            style: AppTextStyle.headingSm.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.primary500,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '${state.totalItemCount}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textDark, size: 22.sp),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
            elevation: 4,
            onSelected: (value) {
              if (value == 'empty') notifier.clearStash();
            },
            itemBuilder: (_) => [
              _menuItem('empty', 'Empty Stash'),
              _menuItem('save', 'Save Stash for Later'),
              _menuItem('share', 'Share List'),
              _menuItem('help', 'Help and Pricing Guide'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: AppTextStyle.bodyMd.copyWith(fontSize: 14.sp),
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Expanded(child: _tab(0, 'Items (${ref.watch(stashProvider).items.length})')),
            Container(width: 1, height: 20.h, color: AppColors.white200),
            Expanded(child: _tab(1, 'Delivery Details')),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index, String label) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyle.bodySm.copyWith(
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
              color:
                  isSelected ? AppColors.textDark : AppColors.textGrey,
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }

  // ── Items tab ───────────────────────────────────────────────────────────────

  Widget _buildItemsTab(StashState state, StashNotifier notifier) {
    if (state.isEmpty) {
      return _buildEmptyStash();
    }
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 4.h),
          ...state.items.map((item) => _buildItemRow(item, notifier)),
          SizedBox(height: 16.h),
          _buildPriceSummary(state),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildItemRow(StashItem item, StashNotifier notifier) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food image placeholder
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.primary200,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                item.name[0],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary600,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Info + controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.storeName,
                            style: AppTextStyle.bodySm.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 11.sp,
                            ),
                          ),
                          Text(
                            item.variant,
                            style: AppTextStyle.bodySm.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => notifier.removeItem(item.id),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18.sp,
                        color: const Color(0xFFFF5A5A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    // Qty controls
                    _qtyButton(
                      icon: Icons.remove,
                      onTap: () => notifier.decrementQuantity(item.id),
                      color: AppColors.white200,
                      iconColor: AppColors.textDark,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        '${item.quantity}',
                        style: AppTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    _qtyButton(
                      icon: Icons.add,
                      onTap: () => notifier.incrementQuantity(item.id),
                      color: AppColors.primary500,
                      iconColor: AppColors.textDark,
                    ),
                    const Spacer(),
                    Text(
                      _naira(item.totalPrice),
                      style: AppTextStyle.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 14.sp, color: iconColor),
      ),
    );
  }

  Widget _buildPriceSummary(StashState state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Price Summary',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.info_outline,
                  size: 14.sp, color: AppColors.textGrey),
            ],
          ),
          SizedBox(height: 12.h),
          _summaryRow('Subtotal', state.subtotal),
          SizedBox(height: 6.h),
          _summaryRow('Delivery Fee', state.deliveryFee),
          SizedBox(height: 6.h),
          _summaryRow(
              'Service Fee (${5}%)', state.serviceFee),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Divider(height: 1, color: AppColors.white200),
          ),
          Row(
            children: [
              Text(
                'Grand Total',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
              const Spacer(),
              Text(
                _naira(state.grandTotal),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyle.bodySm.copyWith(
            color: AppColors.textGrey,
            fontSize: 12.sp,
          ),
        ),
        const Spacer(),
        Text(
          _naira(amount),
          style: AppTextStyle.bodySm.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStash() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 44.sp, color: AppColors.grey500),
            ),
            SizedBox(height: 20.h),
            Text(
              'Your Stash is Empty',
              style: AppTextStyle.headingSm.copyWith(
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add items to your stash to get started',
              style:
                  AppTextStyle.bodyMd.copyWith(color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Delivery Details tab ────────────────────────────────────────────────────

  Widget _buildDeliveryTab(
      BuildContext context, StashState state, StashNotifier notifier) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Details',
            style: AppTextStyle.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 16.h),

          // Delivery address
          Text(
            'Delivery Address',
            style: AppTextStyle.bodySm.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 6.h),
          GestureDetector(
            onTap: () => _showSelectLocation(context, notifier),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.white200),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18.sp, color: AppColors.textGrey),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      state.deliveryAddress,
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textDark,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  Icon(Icons.edit_outlined,
                      size: 18.sp, color: AppColors.textGrey),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Special instructions
          Text(
            'Special Instructions (Optional)',
            style: AppTextStyle.bodySm.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.white200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 14.h, 0, 0),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      size: 18.sp, color: AppColors.textGrey),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _instructionsController,
                    maxLines: 4,
                    onChanged: notifier.updateSpecialInstructions,
                    decoration: InputDecoration(
                      hintText:
                          'E.g., Call when you arrive, leave at the door...',
                      hintStyle: AppTextStyle.bodySm.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 12.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
                    ),
                    style: AppTextStyle.bodyMd.copyWith(fontSize: 13.sp),
                  ),
                ),
                SizedBox(width: 14.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, StashState state) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.white200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 13.sp,
                ),
              ),
              Text(
                _naira(state.grandTotal),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isEmpty
                  ? null
                  : () => context.pushNamed(RouteNames.checkout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary500,
                disabledBackgroundColor: AppColors.buttonDisabled,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r)),
                elevation: 0,
              ),
              child: Text(
                'Checkout',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Select Location bottom sheet ────────────────────────────────────────────

  void _showSelectLocation(BuildContext context, StashNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectLocationSheet(
        onSelect: (address) {
          notifier.updateDeliveryAddress(address);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _naira(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final result = StringBuffer('₦');
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write(',');
      result.write(parts[i]);
    }
    return result.toString();
  }
}

// ── Select Location Sheet ─────────────────────────────────────────────────────

class _SelectLocationSheet extends StatefulWidget {
  final void Function(String) onSelect;
  const _SelectLocationSheet({required this.onSelect});

  @override
  State<_SelectLocationSheet> createState() => _SelectLocationSheetState();
}

class _SelectLocationSheetState extends State<_SelectLocationSheet> {
  final _searchController = TextEditingController();
  List<SavedLocation> _filtered = SavedLocation.mockLocations;

  void _onSearch(String query) {
    setState(() {
      _filtered = SavedLocation.mockLocations
          .where((l) => l.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      color: AppColors.primary600, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Select Location',
                    style: AppTextStyle.headingSm
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 16.sp),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close,
                        size: 20.sp, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 12.w),
                    Icon(Icons.search,
                        color: AppColors.textGrey, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Search markets, stores...',
                          hintStyle: AppTextStyle.bodySm
                              .copyWith(fontSize: 13.sp),
                          border: InputBorder.none,
                        ),
                        style: AppTextStyle.bodyMd.copyWith(fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: GestureDetector(
                onTap: () => widget.onSelect('Current Location'),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary500,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.near_me,
                            size: 16.sp, color: AppColors.textDark),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Use Current Location',
                        style: AppTextStyle.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          size: 18.sp, color: AppColors.textGrey),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SAVED LOCATIONS',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final loc = _filtered[i];
                  return GestureDetector(
                    onTap: () => widget.onSelect(loc.name),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 18.sp, color: AppColors.primary600),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.name,
                                  style: AppTextStyle.labelMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                Text(
                                  '${loc.type} • ${loc.distance}',
                                  style: AppTextStyle.bodySm.copyWith(
                                    color: AppColors.textGrey,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 18.sp, color: AppColors.grey500),
                        ],
                      ),
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
