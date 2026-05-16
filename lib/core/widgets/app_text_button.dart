import 'package:flutter/material.dart';

class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? foregroundColor;
  final Color? disabledForegroundColor;
  final Color? overlayColor;
  final double? borderRadius;
  final TextStyle? textStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextDecoration? decoration;
  final Widget? icon;
  final Widget? suffixIcon;
  final IconAlignment iconAlignment;
  final AlignmentGeometry? alignment;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.foregroundColor,
    this.disabledForegroundColor,
    this.overlayColor,
    this.borderRadius,
    this.textStyle,
    this.fontSize,
    this.fontWeight,
    this.decoration,
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

    final button = TextButton(
      onPressed: isLoading ? null : onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        disabledForegroundColor: disabledForegroundColor,
        padding: padding,
        alignment: alignment,
        shape: borderRadius != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius!),
              )
            : null,
        textStyle: textStyle ??
            (fontSize != null || fontWeight != null || decoration != null
                ? TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    decoration: decoration,
                  )
                : null),
        minimumSize: width != null || height != null
            ? Size(width ?? 0, height ?? 48)
            : null,
        overlayColor: overlayColor,
        iconAlignment: iconAlignment,
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor ?? theme.colorScheme.primary,
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
