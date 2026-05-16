import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hustlers/core/constants/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final double? elevation;
  final double? borderRadius;
  final BorderSide? side;
  final TextStyle? textStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Widget? icon;
  final Widget? suffixIcon;
  final IconAlignment iconAlignment;
  final AlignmentGeometry? alignment;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.elevation,
    this.borderRadius,
    this.side,
    this.textStyle,
    this.fontSize,
    this.fontWeight,
    this.icon,
    this.suffixIcon,
    this.iconAlignment = IconAlignment.start,
    this.alignment,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor?? AppColors.secondary500,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: disabledBackgroundColor,
        disabledForegroundColor: disabledForegroundColor,
        elevation: elevation,
        padding: padding,
        alignment: alignment,
        shape: borderRadius != null || side != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius ?? 26.sp),
                side: side ?? BorderSide.none,
              )
            : null,
        textStyle: textStyle ??
            (fontSize != null || fontWeight != null
                ? TextStyle(fontSize: fontSize, fontWeight: fontWeight)
                : null),
        minimumSize: width != null || height != null
            ? Size(width ?? 0, height ?? 56)
            : null,
        iconAlignment: iconAlignment,
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor ?? theme.colorScheme.onPrimary,
              ),
            )
          : _buildChild(),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: isExpanded ? SizedBox(width: double.infinity, child: button) : button,
      );
    }

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildChild() {
    if (icon != null || suffixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(text),
          if (suffixIcon != null) ...[
            const SizedBox(width: 8),
            suffixIcon!,
          ],
        ],
      );
    }
    return Text(text);
  }
}
