import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    this.prefixIcon,
    this.hasError = false,
    this.errorText,
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
  final IconData? prefixIcon;
  final bool hasError;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final showError = hasError || (errorText?.isNotEmpty ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            cursorColor: context.appColorScheme.primary,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.appText,
            ),
            decoration: InputDecoration(
              hintText: hintText.tr,
              hintStyle: TextStyle(
                color: context.appMutedText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: context.appField,
              prefixIcon:
                  prefixIcon == null
                      ? null
                      : Icon(
                        prefixIcon,
                        size: 20,
                        color:
                            showError
                                ? AppColors.errorCoral
                                : context.appMutedText,
                      ),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: showError ? AppColors.errorCoral : context.appBorder,
                  width: showError ? 1.4 : 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color:
                      showError ? AppColors.errorCoral : AppColors.primaryGreen,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: context.appBorder),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child:
              errorText?.isNotEmpty == true
                  ? Padding(
                    key: ValueKey<String>('field-error-$errorText'),
                    padding: const EdgeInsets.only(top: 6, left: 16, right: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        errorText!.tr,
                        style: const TextStyle(
                          color: AppColors.errorCoral,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
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
    this.errorText,
    this.prefixIcon = Icons.lock_outline_rounded,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final String? errorText;
  final IconData prefixIcon;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final showError =
        widget.hasError || (widget.errorText?.isNotEmpty ?? false);
    return AuthTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      hasError: widget.hasError,
      errorText: widget.errorText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: IconButton(
        tooltip: (_obscure ? 'Show password' : 'Hide password').tr,
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18,
          color: showError ? AppColors.errorCoral : context.appMutedText,
        ),
      ),
    );
  }
}

class AuthInlineError extends StatelessWidget {
  const AuthInlineError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 180),
    child:
        message?.isNotEmpty == true
            ? Container(
              key: ValueKey<String>('auth-error-$message'),
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorCoral.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.errorCoral.withValues(alpha: 0.32),
                ),
              ),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: AppColors.errorCoral,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message!.tr,
                        style: const TextStyle(
                          color: AppColors.errorCoral,
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            : const SizedBox.shrink(),
  );
}
