import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../constants/app_colors.dart';

class OtpInputField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final int length;

  const OtpInputField({
    super.key,
    this.controller,
    this.onCompleted,
    this.onChanged,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 70,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary500, width: 1.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary500, width: 1.5),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      onCompleted: onCompleted,
      onChanged: onChanged,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      keyboardType: TextInputType.number,
      mainAxisAlignment: MainAxisAlignment.center,
      separatorBuilder: (index) => const SizedBox(width: 12),
    );
  }
}
