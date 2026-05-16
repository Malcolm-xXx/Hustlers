import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../data/models/store_item_model.dart';
import '../providers/seller_provider.dart';

class AddEditItemView extends ConsumerStatefulWidget {
  final StoreItemModel? existingItem;

  const AddEditItemView({super.key, this.existingItem});

  @override
  ConsumerState<AddEditItemView> createState() => _AddEditItemViewState();
}

class _AddEditItemViewState extends ConsumerState<AddEditItemView> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _shelfLifeController;
  late final TextEditingController _salePriceController;

  String? _selectedCategory;
  bool _promoExpanded = false;
  bool _saleEnabled = false;
  bool _hasImage = false;

  bool get _isEditing => widget.existingItem != null;

  static const _categories = [
    'Grains',
    'Tubers',
    'Drinks',
    'Proteins',
    'Oil/Spices',
    'Fresh Market',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
        text: item != null ? item.price.toStringAsFixed(0) : '');
    _unitController = TextEditingController(text: item?.unit ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _shelfLifeController =
        TextEditingController(text: item?.shelfLife ?? '');
    _salePriceController = TextEditingController(
        text: item?.salePrice != null
            ? item!.salePrice!.toStringAsFixed(0)
            : '');
    _selectedCategory = item?.category;
    _saleEnabled = item?.isOnSale ?? false;
    _promoExpanded = _saleEnabled;
    _hasImage = item?.imageUrl.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _shelfLifeController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.isNotEmpty &&
      _priceController.text.isNotEmpty &&
      _unitController.text.isNotEmpty &&
      _selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
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
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Item' : 'Add a New Item',
                      style: AppTextStyle.headingSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_isEditing || _isValid)
                    GestureDetector(
                      onTap: _isValid ? _onPublish : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: _isEditing
                              ? AppColors.verifiedGreen
                              : AppColors.secondary500,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          _isEditing ? 'Save' : 'Publish',
                          style: AppTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),

                    // Upload photo
                    _buildLabel('Upload photo of item *'),
                    SizedBox(height: 8.h),
                    _buildPhotoUpload(),

                    SizedBox(height: 24.h),

                    // Name
                    _buildLabel('Name of Item *'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Enter Name',
                    ),

                    SizedBox(height: 20.h),

                    // Category
                    _buildLabel('Select Category *'),
                    SizedBox(height: 8.h),
                    _buildCategoryDropdown(),

                    SizedBox(height: 20.h),

                    // Price + Unit row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Regular Price *'),
                              SizedBox(height: 8.h),
                              _buildTextField(
                                controller: _priceController,
                                hint: '',
                                prefix: '\u20A6',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Unit *'),
                              SizedBox(height: 8.h),
                              _buildTextField(
                                controller: _unitController,
                                hint: 'e.g Per Congo',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Promotion Settings
                    _buildPromotionSettings(),

                    SizedBox(height: 20.h),

                    // Description
                    _buildLabel('Product Description'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: _descriptionController,
                      hint: 'Enter Description',
                      maxLines: 4,
                    ),

                    SizedBox(height: 20.h),

                    // Shelf life
                    _buildLabel('Shelf life'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: _shelfLifeController,
                      hint: 'e.g 6 months if kept in cool and dry place',
                    ),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
              color: Colors.white,
              child: Column(
                children: [
                  AppPrimaryButton(
                    text: _isEditing ? 'Save Changes' : 'Publish Now',
                    onPressed: _isValid ? _onPublish : null,
                    backgroundColor: _isValid
                        ? AppColors.secondary500
                        : AppColors.buttonDisabled,
                    disabledBackgroundColor: AppColors.buttonDisabled,
                    disabledForegroundColor: AppColors.white,
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Save as draft
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.grey50),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.r),
                        ),
                      ),
                      child: Text(
                        'Save as Draft',
                        style: AppTextStyle.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyle.labelMd.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13.sp,
      ),
    );
  }

  Widget _buildPhotoUpload() {
    if (_hasImage && widget.existingItem != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          height: 180.h,
          color: AppColors.grey50,
          child: Image.network(
            widget.existingItem!.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildUploadPlaceholder(),
          ),
        ),
      );
    }
    return _buildUploadPlaceholder();
  }

  Widget _buildUploadPlaceholder() {
    return GestureDetector(
      onTap: () {
        // TODO: Image picker
        setState(() => _hasImage = true);
      },
      child: Container(
        width: double.infinity,
        height: 180.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.grey50,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.grey500,
            radius: 12.r,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.image_outlined,
                    size: 28.sp, color: AppColors.primary500),
              ),
              SizedBox(height: 12.h),
              Text(
                'Tap to take or upload image (10MB max)',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      style: AppTextStyle.bodyMd.copyWith(
        color: AppColors.textDark,
        fontSize: 14.sp,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyle.bodyMd.copyWith(
          color: AppColors.textGrey.withOpacity(0.4),
          fontSize: 13.sp,
        ),
        prefixText: prefix,
        prefixStyle: AppTextStyle.bodyMd.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: Text(
            'Select the category of the item',
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.textGrey.withOpacity(0.4),
              fontSize: 13.sp,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: AppColors.textGrey, size: 22.sp),
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: AppTextStyle.bodyMd),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  Widget _buildPromotionSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _promoExpanded = !_promoExpanded),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.flash_on,
                        size: 20.sp, color: AppColors.white),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Promotion Settings',
                    style: AppTextStyle.labelMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_saleEnabled) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Active',
                        style: AppTextStyle.bodySm.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _promoExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 22.sp,
                    color: AppColors.textGrey,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_promoExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enable Sale Price toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Sale Price',
                            style: AppTextStyle.labelMd.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                          ),
                          Text(
                            'Offer a discounted price to boost sales',
                            style: AppTextStyle.bodySm.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _saleEnabled,
                        onChanged: (val) =>
                            setState(() => _saleEnabled = val),
                        activeThumbColor: AppColors.white,
                        activeTrackColor: AppColors.primary500,
                      ),
                    ],
                  ),

                  if (_saleEnabled) ...[
                    SizedBox(height: 12.h),
                    Text(
                      'Discounted Price',
                      style: AppTextStyle.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _salePriceController,
                            hint: '',
                            prefix: '\u20A6',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '-${_calculateDiscount()}%',
                            style: AppTextStyle.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _calculateDiscount() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final sale = double.tryParse(_salePriceController.text) ?? 0;
    if (price <= 0 || sale <= 0 || sale >= price) return '0';
    return ((price - sale) / price * 100).round().toString();
  }

  void _onPublish() {
    final notifier = ref.read(sellerProvider.notifier);
    final item = StoreItemModel(
      id: widget.existingItem?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      price: double.tryParse(_priceController.text) ?? 0,
      salePrice: _saleEnabled
          ? double.tryParse(_salePriceController.text)
          : null,
      unit: _unitController.text.trim(),
      description: _descriptionController.text.trim(),
      shelfLife: _shelfLifeController.text.trim(),
      imageUrl: widget.existingItem?.imageUrl ?? '',
      createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      notifier.updateItem(item.id, item);
    } else {
      notifier.addItem(item);
    }
    context.pop();
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    const dashWidth = 8.0;
    const dashSpace = 5.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
