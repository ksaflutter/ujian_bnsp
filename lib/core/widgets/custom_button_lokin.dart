import 'package:flutter/material.dart';

import '../constants/app_colors_lokin.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final IconData? icon; // Added this parameter
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isOutlined;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final bool isGradient;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.borderRadius,
    this.icon, // Added this parameter
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isOutlined = false,
    this.elevation,
    this.padding,
    this.textStyle,
    this.isGradient = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ?? AppColorsLokin.primary;
    final defaultTextColor = textColor ?? Colors.white;
    final defaultBorderColor = borderColor ?? defaultBackgroundColor;
    final defaultHeight = height ?? 56.0;
    final defaultBorderRadius = borderRadius ?? 12.0;

    if (isGradient || gradient != null) {
      return _buildGradientButton(
        defaultTextColor,
        defaultHeight,
        defaultBorderRadius,
      );
    }

    if (isOutlined) {
      return _buildOutlinedButton(
        defaultBackgroundColor,
        defaultTextColor,
        defaultBorderColor,
        defaultHeight,
        defaultBorderRadius,
      );
    }

    return _buildElevatedButton(
      defaultBackgroundColor,
      defaultTextColor,
      defaultHeight,
      defaultBorderRadius,
    );
  }

  Widget _buildElevatedButton(
    Color bgColor,
    Color txtColor,
    double btnHeight,
    double btnBorderRadius,
  ) {
    return SizedBox(
      width: width,
      height: btnHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          disabledBackgroundColor: bgColor.withOpacity(0.6),
          disabledForegroundColor: txtColor.withOpacity(0.6),
          elevation: elevation ?? 2,
          shadowColor: bgColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnBorderRadius),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: _buildButtonContent(txtColor),
      ),
    );
  }

  Widget _buildOutlinedButton(
    Color bgColor,
    Color txtColor,
    Color borderClr,
    double btnHeight,
    double btnBorderRadius,
  ) {
    return SizedBox(
      width: width,
      height: btnHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: txtColor,
          disabledForegroundColor: txtColor.withOpacity(0.6),
          side: BorderSide(
            color: isLoading ? borderClr.withOpacity(0.6) : borderClr,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnBorderRadius),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: _buildButtonContent(txtColor),
      ),
    );
  }

  Widget _buildGradientButton(
    Color txtColor,
    double btnHeight,
    double btnBorderRadius,
  ) {
    final buttonGradient = gradient ??
        const LinearGradient(
          colors: [AppColorsLokin.primary, AppColorsLokin.secondary],
        );

    return Container(
      width: width,
      height: btnHeight,
      decoration: BoxDecoration(
        gradient: isLoading ? null : buttonGradient,
        color: isLoading ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(btnBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColorsLokin.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(btnBorderRadius),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildButtonContent(txtColor),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(Color txtColor) {
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(txtColor),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Memuat...',
            style: textStyle?.copyWith(color: txtColor) ??
                TextStyle(
                  color: txtColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    List<Widget> children = [];

    // Use icon parameter if provided, otherwise use prefixIcon
    final displayIcon = icon ?? prefixIcon;

    if (displayIcon != null) {
      children.add(Icon(displayIcon, size: 20, color: txtColor));
      children.add(const SizedBox(width: 8));
    }

    children.add(
      Flexible(
        child: Text(
          text,
          style: textStyle?.copyWith(color: txtColor) ??
              TextStyle(
                color: txtColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (suffixIcon != null) {
      children.add(const SizedBox(width: 8));
      children.add(Icon(suffixIcon, size: 20, color: txtColor));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

// Loading Button with different styles
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      textColor: textColor,
      width: width,
      height: height,
      isLoading: isLoading,
    );
  }
}

// Gradient Button
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? prefixIcon;
  final IconData? suffixIcon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.textColor,
    this.width,
    this.height,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      textColor: textColor,
      width: width,
      height: height,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isGradient: true,
      gradient: gradient,
    );
  }
}

// Icon Button with custom styling
class IconButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final String? tooltip;
  final bool isCircular;

  const IconButtonCustom({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.tooltip,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = size ?? 48.0;
    final icnSize = iconSize ?? 24.0;
    final bgColor = backgroundColor ?? AppColorsLokin.primary;
    final icnColor = iconColor ?? Colors.white;

    Widget button = Container(
      width: btnSize,
      height: btnSize,
      decoration: BoxDecoration(
        color: bgColor,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: isCircular
              ? BorderRadius.circular(btnSize / 2)
              : BorderRadius.circular(12),
          child: Icon(
            icon,
            size: icnSize,
            color: icnColor,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
