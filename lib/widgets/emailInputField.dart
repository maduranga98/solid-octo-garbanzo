import 'package:flutter/material.dart';
import 'package:poem_application/widgets/inputfields.dart';

class EmailInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool required;

  const EmailInputField({
    super.key,
    this.label = 'Email',
    this.hint = 'Enter your email address',
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
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      required: required,
      validator: validator ?? _defaultEmailValidator,
      prefixIcon: const Icon(Icons.email_outlined),
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (required && (value == null || value.isEmpty)) {
      return 'Email is required';
    }
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Enter a valid email address';
      }
    }
    return null;
  }
}
