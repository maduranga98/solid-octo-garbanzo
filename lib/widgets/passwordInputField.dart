import 'package:flutter/material.dart';
import 'package:poem_application/widgets/inputfields.dart';

class PasswordInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool required;

  const PasswordInputField({
    super.key,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.controller,
    this.onChanged,
    this.validator,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return InputField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      required: required,
      validator: validator ?? _defaultPasswordValidator,
      prefixIcon: const Icon(Icons.lock_outlined),
    );
  }

  String? _defaultPasswordValidator(String? value) {
    if (required && (value == null || value.isEmpty)) {
      return 'Password is required';
    }
    if (value != null && value.isNotEmpty && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
