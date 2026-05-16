import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../providers/hustle_list_provider.dart';
import '../widgets/delivery_time_bottom_sheet.dart';
import '../widgets/new_item_bottom_sheet.dart';

class CreateHustleListView extends ConsumerStatefulWidget {
  const CreateHustleListView({super.key});

  @override
  ConsumerState<CreateHustleListView> createState() =>
      _CreateHustleListViewState();
}

class _CreateHustleListViewState extends ConsumerState<CreateHustleListView> {
  final _deliveryFeeController = TextEditingController();

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hustleListProvider);
    final notifier = ref.read(hustleListProvider.notifier);

    // Sync delivery fee controller
    if (state.deliveryFee != null &&
        _deliveryFeeController.text.isEmpty) {
      _deliveryFeeController.text =
          state.deliveryFee!.toStringAsFixed(0);
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Container(
              color: Colors.white,
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
                    'Create a Hustle List',
                    style: AppTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // TODO: Save draft
                    },
                    child: Text(
                      'Save Draft',
                      style: AppTextStyle.labelMd.copyWith(
                        color: state.items.isNotEmpty
                            ? AppColors.primary500
                            : AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 8.h),

                    // Add Item button
                    _buildAddItemButton(context, notifier),

                    // Items list
                    if (state.items.isNotEmpty) ...[
                      ...state.items.map((item) =>
                          _buildItemCard(item, notifier)),
                    ],

                    SizedBox(height: 8.h),

                    // Delivery Fee section
                    _buildDeliveryFeeSection(state, notifier),

                    SizedBox(height: 8.h),

                    // Shopping Location section
                    _buildShoppingLocationSection(state, notifier),

                    SizedBox(height: 8.h),

                    // Delivery Timeline section
                    _buildDeliveryTimelineSection(state, notifier),

                    SizedBox(height: 8.h),

                    // Direct Request section
                    _buildDirectRequestSection(state, notifier),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
              child: AppPrimaryButton(
                text: state.directRequestEnabled &&
                        state.selectedHustlerName != null
                    ? 'Send to ${state.selectedHustlerName}'
                    : state.directRequestEnabled
                        ? 'Post List'
                        : 'Create List',
                onPressed: state.canPostList
                    ? () => notifier.navigateToSuccess(context)
                    : null,
                backgroundColor: state.canPostList
                    ? AppColors.secondary500
                    : AppColors.buttonDisabled,
                disabledBackgroundColor: AppColors.buttonDisabled,
                disabledForegroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemButton(
      BuildContext context, HustleListNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: GestureDetector(
        onTap: () async {
          final item = await NewItemBottomSheet.show(context);
          if (item != null) {
            notifier.addItem(item);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary500, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline,
                  size: 20.sp, color: AppColors.primary500),
              SizedBox(width: 10.w),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    children: [
                      const TextSpan(text: 'Add Item '),
                      TextSpan(
                        text: '(e.g 2kg of meat, 1 Congo of Garri)',
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 22.sp, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(HustleItem item, HustleListNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.price != null) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.monetization_on_outlined,
                          size: 14.sp, color: AppColors.textGrey),
                      SizedBox(width: 4.w),
                      Text(
                        '\u20A6${item.price!.toStringAsFixed(0)}',
                        style: AppTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.note != null) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 12.sp, color: AppColors.textGrey),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          item.note!,
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final updated = await NewItemBottomSheet.show(
                context,
                existingItem: item,
              );
              if (updated != null) {
                notifier.updateItem(item.id, updated);
              }
            },
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.edit_outlined,
                  size: 18.sp, color: AppColors.textGrey),
            ),
          ),
          GestureDetector(
            onTap: () => notifier.removeItem(item.id),
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.delete_outline,
                  size: 18.sp, color: AppColors.logOutRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryFeeSection(
      HustleListState state, HustleListNotifier notifier) {
    final feeChips = [500.0, 700.0, 1000.0, 1500.0];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    '\u20A6',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B4EFF),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Fee',
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 12.sp, color: AppColors.textGrey),
                      SizedBox(width: 4.w),
                      Text(
                        'Higher fees attract Hustlers faster',
                        style: AppTextStyle.bodySm.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Fee input
          TextField(
            controller: _deliveryFeeController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final fee = double.tryParse(val);
              if (fee != null) notifier.setDeliveryFee(fee);
            },
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 16.w, right: 4.w),
                child: Text(
                  '\u20A6',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              hintText: '500',
              hintStyle: AppTextStyle.bodyMd.copyWith(
                color: AppColors.textGrey.withOpacity(0.4),
              ),
              filled: true,
              fillColor: AppColors.scaffoldBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),

          SizedBox(height: 12.h),

          // Quick chips
          Wrap(
            spacing: 8.w,
            children: feeChips.map((fee) {
              final isSelected = state.deliveryFee == fee;
              return GestureDetector(
                onTap: () {
                  notifier.setDeliveryFee(fee);
                  _deliveryFeeController.text = fee.toStringAsFixed(0);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary100
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary500 : AppColors.grey50,
                    ),
                  ),
                  child: Text(
                    '\u20A6${fee.toStringAsFixed(0)}',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textDark,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingLocationSection(
      HustleListState state, HustleListNotifier notifier) {
    final popularLocations = ['Odo-Ona Market', 'Central Market', 'Campus Store'];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.location_on_outlined,
                    size: 20.sp, color: const Color(0xFF4285F4)),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shopping Location',
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Specify a market or store (optional)',
                    style: AppTextStyle.bodySm.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Location selector
          GestureDetector(
            onTap: () async {
              final location = await context
                  .pushNamed<String>(RouteNames.selectLocation);
              if (location != null) {
                notifier.setLocation(location);
              }
            },
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18.sp, color: AppColors.textGrey),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      state.selectedLocation ?? 'Select location',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: state.selectedLocation != null
                            ? AppColors.textDark
                            : AppColors.textGrey,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down,
                      size: 22.sp, color: AppColors.textGrey),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            'POPULAR',
            style: AppTextStyle.bodySm.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: popularLocations.map((loc) {
              final isSelected = state.selectedLocation == loc;
              return GestureDetector(
                onTap: () => notifier.setLocation(loc),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary100
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary500 : AppColors.grey50,
                    ),
                  ),
                  child: Text(
                    loc,
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textDark,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimelineSection(
      HustleListState state, HustleListNotifier notifier) {
    final timeChips = ['In 30 mins', 'In 1 hour', 'In 2 hours', 'Today'];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.access_time,
                    size: 20.sp, color: const Color(0xFFFF9800)),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Delivery Timeline',
                        style: AppTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          color: AppColors.logOutRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 12.sp, color: AppColors.textGrey),
                      SizedBox(width: 4.w),
                      Text(
                        'Urgent timelines may require higher fees',
                        style: AppTextStyle.bodySm.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Time selector
          GestureDetector(
            onTap: () async {
              final time = await DeliveryTimeBottomSheet.show(
                context,
                currentSelection: state.deliveryTime,
              );
              if (time != null) {
                notifier.setDeliveryTime(time);
              }
            },
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 18.sp, color: AppColors.textGrey),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      state.deliveryTime ?? 'Select delivery time',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: state.deliveryTime != null
                            ? AppColors.textDark
                            : AppColors.textGrey,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down,
                      size: 22.sp, color: AppColors.textGrey),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: timeChips.map((time) {
              final isSelected = state.deliveryTime == time;
              return GestureDetector(
                onTap: () => notifier.setDeliveryTime(time),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary100
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary500 : AppColors.grey50,
                    ),
                  ),
                  child: Text(
                    time,
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textDark,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectRequestSection(
      HustleListState state, HustleListNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable Direct Request',
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Send only to a specific hustler',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
              Switch(
                value: state.directRequestEnabled,
                onChanged: (_) => notifier.toggleDirectRequest(),
                activeThumbColor: AppColors.primary500,
                activeTrackColor: AppColors.primary200,
              ),
            ],
          ),

          // Direct request content
          if (state.directRequestEnabled) ...[
            SizedBox(height: 16.h),

            // Search field
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search Hustler',
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.textGrey.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Icon(Icons.search,
                      size: 20.sp, color: AppColors.textGrey),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'Choose From my Favourites',
              style: AppTextStyle.labelMd.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),

            // Favourites grid
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: notifier.favouriteHustlers.map((hustler) {
                final isSelected =
                    state.selectedHustlerId == hustler.id;
                return GestureDetector(
                  onTap: () =>
                      notifier.selectHustler(hustler.id, hustler.name),
                  child: SizedBox(
                    width: 72.w,
                    child: Column(
                      children: [
                        Container(
                          width: 52.w,
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary100
                                : AppColors.scaffoldBackground,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primary500,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 28.sp,
                            color: isSelected
                                ? AppColors.primary500
                                : AppColors.grey400,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          hustler.name,
                          style: AppTextStyle.bodySm.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
