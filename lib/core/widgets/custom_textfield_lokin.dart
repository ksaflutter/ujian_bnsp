import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors_lokin.dart';

class CustomTextFieldLokin extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool autofocus;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;

  const CustomTextFieldLokin({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius,
    this.contentPadding,
    this.textStyle,
    this.hintStyle,
    this.autofocus = false,
    this.errorText,
    this.prefix,
    this.suffix,
    required String label,
    required String hint,
  });

  @override
  State<CustomTextFieldLokin> createState() => _CustomTextFieldLokinState();
}

class _CustomTextFieldLokinState extends State<CustomTextFieldLokin> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = widget.borderRadius ?? 12.0;
    final defaultFillColor = widget.fillColor ?? Colors.white;
    final defaultBorderColor = widget.borderColor ?? AppColorsLokin.border;
    final defaultFocusedBorderColor =
        widget.focusedBorderColor ?? AppColorsLokin.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColorsLokin.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(defaultBorderRadius),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: defaultFocusedBorderColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            style: widget.textStyle ??
                TextStyle(
                  fontSize: 16,
                  color: AppColorsLokin.textPrimary,
                  fontFamily: 'Poppins',
                ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ??
                  TextStyle(
                    fontSize: 16,
                    color: AppColorsLokin.textSecondary,
                    fontFamily: 'Poppins',
                  ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? defaultFocusedBorderColor
                          : AppColorsLokin.textSecondary,
                      size: 22,
                    )
                  : null,
              prefix: widget.prefix,
              suffixIcon: widget.suffixIcon,
              suffix: widget.suffix,
              filled: true,
              fillColor: widget.enabled
                  ? defaultFillColor
                  : AppColorsLokin.border.withOpacity(0.3),
              contentPadding: widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(color: defaultBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(color: defaultBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(
                  color: defaultFocusedBorderColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(color: AppColorsLokin.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(color: AppColorsLokin.error, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(
                  color: AppColorsLokin.border.withOpacity(0.5),
                ),
              ),
              errorText: widget.errorText,
              errorStyle: TextStyle(
                fontSize: 12,
                color: AppColorsLokin.error,
                fontFamily: 'Poppins',
              ),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

// Password TextField with toggle visibility
class PasswordTextFieldLokin extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final FocusNode? focusNode;

  const PasswordTextFieldLokin({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<PasswordTextFieldLokin> createState() => _PasswordTextFieldLokinState();
}

class _PasswordTextFieldLokinState extends State<PasswordTextFieldLokin> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextFieldLokin(
      controller: widget.controller,
      hintText: widget.hintText ?? 'Masukkan password',
      labelText: widget.labelText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColorsLokin.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      label: '',
      hint: '',
    );
  }
}

// Search TextField
class SearchTextFieldLokin extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;

  const SearchTextFieldLokin({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFieldLokin(
      controller: controller,
      hintText: hintText ?? 'Cari...',
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: Icon(Icons.clear, color: AppColorsLokin.textSecondary),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      label: '',
      hint: '',
    );
  }
}

// Multiline TextField for comments/descriptions
class MultilineTextFieldLokin extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final int? maxLength;

  const MultilineTextFieldLokin({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.onChanged,
    this.maxLines = 3,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFieldLokin(
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      label: '',
      hint: '',
    );
  }
}
