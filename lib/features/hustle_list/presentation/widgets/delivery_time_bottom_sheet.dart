import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';

class DeliveryTimeBottomSheet extends StatefulWidget {
  final String? currentSelection;

  const DeliveryTimeBottomSheet({super.key, this.currentSelection});

  static Future<String?> show(BuildContext context, {String? currentSelection}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          DeliveryTimeBottomSheet(currentSelection: currentSelection),
    );
  }

  @override
  State<DeliveryTimeBottomSheet> createState() =>
      _DeliveryTimeBottomSheetState();
}

class _DeliveryTimeBottomSheetState extends State<DeliveryTimeBottomSheet> {
  String? _selected;
  int _hours = 12;
  int _minutes = 0;
  bool _isPm = true;

  final _quickOptions = [
    'In 30 mins',
    'In 1 hour',
    'In 2 hours',
    'In 3 hours',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 20.sp, color: AppColors.textDark),
                  SizedBox(width: 8.w),
                  Text(
                    'Select Delivery Time',
                    style: AppTextStyle.headingSm.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child:
                    Icon(Icons.close, size: 22.sp, color: AppColors.textDark),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Quick Select
          Text(
            'QUICK SELECT',
            style: AppTextStyle.bodySm.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _quickOptions.map((option) {
              final isSelected = _selected == option;
              return GestureDetector(
                onTap: () => setState(() => _selected = option),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary500 : AppColors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary500 : AppColors.grey50,
                    ),
                  ),
                  child: Text(
                    option,
                    style: AppTextStyle.bodySm.copyWith(
                      color:
                          isSelected ? AppColors.textDark : AppColors.textDark,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 24.h),

          // Custom Time
          Text(
            'CUSTOM TIME',
            style: AppTextStyle.bodySm.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),

          // Time picker row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeScroller(
                value: _hours,
                min: 1,
                max: 12,
                onChanged: (v) => setState(() {
                  _hours = v;
                  _selected = null;
                }),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              _buildTimeScroller(
                value: _minutes,
                min: 0,
                max: 59,
                padZero: true,
                onChanged: (v) => setState(() {
                  _minutes = v;
                  _selected = null;
                }),
              ),
              SizedBox(width: 16.w),
              // AM/PM toggle
              Column(
                children: [
                  _buildAmPmButton('AM', !_isPm),
                  SizedBox(height: 4.h),
                  _buildAmPmButton('PM', _isPm),
                ],
              ),
            ],
          ),

          SizedBox(height: 28.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: AppColors.grey50),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: AppTextStyle.labelMd.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final result = _selected ??
                        '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')} ${_isPm ? 'PM' : 'AM'}';
                    Navigator.of(context).pop(result);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Center(
                      child: Text(
                        'Confirm',
                        style: AppTextStyle.labelMd.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmPmButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _isPm = label == 'PM'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary500 : AppColors.grey50,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: AppTextStyle.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeScroller({
    required int value,
    required int min,
    required int max,
    bool padZero = false,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      width: 72.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => onChanged(value < max ? value + 1 : min),
            child: Icon(Icons.keyboard_arrow_up,
                size: 20.sp, color: AppColors.textGrey),
          ),
          Text(
            padZero ? value.toString().padLeft(2, '0') : value.toString(),
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontFamily: 'Poppins',
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(value > min ? value - 1 : max),
            child: Icon(Icons.keyboard_arrow_down,
                size: 20.sp, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
