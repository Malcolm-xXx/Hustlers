import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';

class AddCardView extends ConsumerStatefulWidget {
  const AddCardView({super.key});

  @override
  ConsumerState<AddCardView> createState() => _AddCardViewState();
}

class _AddCardViewState extends ConsumerState<AddCardView> {
  final _nameController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _saveAsDefault = false;

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _cardController.text.replaceAll(' ', '').length == 16 &&
      _expiryController.text.length == 5 &&
      _cvcController.text.length == 3;

  String get _detectedType {
    final raw = _cardController.text.replaceAll(' ', '');
    if (raw.startsWith('5') || raw.startsWith('2')) return 'mastercard';
    if (raw.startsWith('4')) return 'visa';
    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Name on Card'),
                    SizedBox(height: 6.h),
                    _buildField(
                      controller: _nameController,
                      hint: 'Enter Name',
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 16.h),

                    _fieldLabel('Card Number'),
                    SizedBox(height: 6.h),
                    _buildCardNumberField(),
                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Expiry Date'),
                              SizedBox(height: 6.h),
                              _buildField(
                                controller: _expiryController,
                                hint: 'MM/YY',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _ExpiryInputFormatter(),
                                ],
                                maxLength: 5,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('CVC'),
                              SizedBox(height: 6.h),
                              _buildField(
                                controller: _cvcController,
                                hint: '123',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                maxLength: 3,
                                obscureText: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Save as default checkbox
                    GestureDetector(
                      onTap: () =>
                          setState(() => _saveAsDefault = !_saveAsDefault),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: _saveAsDefault
                                  ? AppColors.primary500
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(5.r),
                              border: Border.all(
                                color: _saveAsDefault
                                    ? AppColors.primary500
                                    : AppColors.grey500,
                                width: 1.5,
                              ),
                            ),
                            child: _saveAsDefault
                                ? Icon(Icons.check_rounded,
                                    size: 13.sp, color: AppColors.textDark)
                                : null,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Save as my default card',
                            style: AppTextStyle.bodyMd.copyWith(
                              fontSize: 13.sp,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Disclaimer + button
            _buildBottom(context),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
            'Add a New Card',
            style: AppTextStyle.headingSm.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Fields ───────────────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyle.bodySm.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.w500,
        fontSize: 13.sp,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscureText = false,
  }) {
    return StatefulBuilder(
      builder: (_, setInner) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        obscureText: obscureText,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyle.bodySm
              .copyWith(color: AppColors.textGrey, fontSize: 13.sp),
          counterText: '',
          filled: true,
          fillColor: AppColors.scaffoldBackground,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
                BorderSide(color: AppColors.primary500, width: 1.5),
          ),
        ),
        style: AppTextStyle.bodyMd.copyWith(fontSize: 14.sp),
      ),
    );
  }

  Widget _buildCardNumberField() {
    return TextField(
      controller: _cardController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CardNumberFormatter(),
      ],
      maxLength: 19, // 16 digits + 3 spaces
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'XXXX XXXX XXXX XXXX',
        hintStyle: AppTextStyle.bodySm
            .copyWith(color: AppColors.textGrey, fontSize: 13.sp),
        counterText: '',
        filled: true,
        fillColor: AppColors.scaffoldBackground,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primary500, width: 1.5),
        ),
        suffixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_detectedType == 'visa' || _detectedType == '')
                Text('VISA',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1F71),
                    )),
              if (_detectedType != 'visa') ...[
                if (_detectedType == '') SizedBox(width: 6.w),
                Container(
                  width: 24.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          width: 16.w,
                          height: 16.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEB001B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8.w,
                        child: Container(
                          width: 16.w,
                          height: 16.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      style: AppTextStyle.bodyMd
          .copyWith(fontSize: 14.sp, letterSpacing: 1.5),
    );
  }

  // ── Bottom (disclaimer + button) ─────────────────────────────────────────────

  Widget _buildBottom(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: RichText(
              text: TextSpan(
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 11.sp,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                      text: 'By adding a new card, you agree to the '),
                  TextSpan(
                    text: 'credit/debit card terms',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.primary600,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFormValid ? () => _addCard(context) : null,
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
                'Add Card',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addCard(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cards are saved automatically after a successful card payment.'),
      ),
    );
    context.pop();
  }
}

// ── Input formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return newValue.copyWith(text: digits);
    }
    final formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
