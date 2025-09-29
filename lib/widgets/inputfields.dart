import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool required;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final String? errorText;
  final String? helperText;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final Color? fillColor;
  final bool filled;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextCapitalization textCapitalization;
  final Brightness? keyboardAppearance;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;

  const InputField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.errorText,
    this.helperText,
    this.contentPadding,
    this.border,
    this.fillColor,
    this.filled = true,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardAppearance,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style:
                    widget.labelStyle ??
                    theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          focusNode: _focusNode,
          textCapitalization: widget.textCapitalization,
          keyboardAppearance: widget.keyboardAppearance,
          autofocus: widget.autofocus,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          style: widget.textStyle ?? theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                widget.hintStyle ??
                theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            errorText: widget.errorText,
            helperText: widget.helperText,
            filled: widget.filled,
            fillColor:
                widget.fillColor ??
                (_isFocused
                    ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                    : colorScheme.surfaceVariant.withValues(alpha: 0.5)),
            contentPadding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: widget.border ?? _buildBorder(colorScheme.outline),
            enabledBorder: widget.border ?? _buildBorder(colorScheme.outline),
            focusedBorder: widget.border ?? _buildBorder(colorScheme.primary),
            errorBorder: widget.border ?? _buildBorder(colorScheme.error),
            focusedErrorBorder:
                widget.border ?? _buildBorder(colorScheme.error),
            counterText: widget.maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.keyboardType == TextInputType.visiblePassword &&
        widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
    );
  }
}
