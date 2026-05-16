import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../providers/hustle_list_provider.dart';

class NewItemBottomSheet extends StatefulWidget {
  final HustleItem? existingItem;

  const NewItemBottomSheet({super.key, this.existingItem});

  static Future<HustleItem?> show(BuildContext context,
      {HustleItem? existingItem}) {
    return showModalBottomSheet<HustleItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewItemBottomSheet(existingItem: existingItem),
    );
  }

  @override
  State<NewItemBottomSheet> createState() => _NewItemBottomSheetState();
}

class _NewItemBottomSheetState extends State<NewItemBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _noteFocus = FocusNode();

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingItem?.name ?? '');
    _priceController = TextEditingController(
      text: widget.existingItem?.price != null
          ? widget.existingItem!.price!.toStringAsFixed(0)
          : '',
    );
    _noteController =
        TextEditingController(text: widget.existingItem?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) return;
    final item = HustleItem(
      id: widget.existingItem?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()),
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.close, size: 24.sp,
                            color: AppColors.textDark),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'New Item',
                        style: AppTextStyle.headingSm.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _isValid ? _submit : null,
                    child: Text(
                      'Add Item',
                      style: AppTextStyle.labelMd.copyWith(
                        color: _isValid
                            ? AppColors.primary500
                            : AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Item name field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    hintText: 'Add item name',
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_priceFocus),
                  ),
                  if (_nameFocus.hasFocus || _nameController.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h, left: 4.w),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 12.sp, color: AppColors.textGrey),
                          SizedBox(width: 4.w),
                          Text(
                            'Be as specific as possible',
                            style: AppTextStyle.bodySm.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Set item price
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on_outlined,
                          size: 16.sp, color: AppColors.textGrey),
                      SizedBox(width: 6.w),
                      Text(
                        'Set item price',
                        style: AppTextStyle.labelSm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _buildTextField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    hintText: '',
                    prefix: Text(
                      '\u20A6 ',
                      style: AppTextStyle.labelMd.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_noteFocus),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Add note
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16.sp, color: AppColors.textGrey),
                      SizedBox(width: 6.w),
                      Text(
                        'Add note for item',
                        style: AppTextStyle.labelSm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _buildTextField(
                    controller: _noteController,
                    focusNode: _noteFocus,
                    hintText:
                        'Enter your note (e.g make sure the tomatoes aren\'t soft)',
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    Widget? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTextStyle.bodyMd.copyWith(
          color: AppColors.textDark,
          fontSize: 14.sp,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyle.bodyMd.copyWith(
            color: AppColors.textGrey.withOpacity(0.5),
            fontSize: 13.sp,
          ),
          prefixIcon: prefix != null
              ? Padding(
                  padding: EdgeInsets.only(left: 16.w, right: 0),
                  child: prefix,
                )
              : null,
          prefixIconConstraints:
              prefix != null ? const BoxConstraints(minWidth: 0) : null,
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.grey50),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primary500, width: 1.5),
          ),
        ),
      ),
    );
  }
}
