import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.obscureText = false,
    this.suffixIcon,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGreen,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.placeholder,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: AppColors.field,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: hasError ? AppColors.errorCoral : Colors.white,
              width: hasError ? 1.4 : 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: hasError ? AppColors.errorCoral : AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      hasError: widget.hasError,
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18,
          color: widget.hasError ? AppColors.errorCoral : AppColors.mutedText,
        ),
      ),
    );
  }
}
