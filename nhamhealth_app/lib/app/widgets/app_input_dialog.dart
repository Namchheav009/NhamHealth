import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../theme/app_colors.dart';

/// A modern, frosted glass card dialog for editing single- or multi-line input values.
/// Styled identically to the AI Food correction dialog.
class AppInputDialog extends StatefulWidget {
  const AppInputDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.exampleText,
    this.icon = Icons.edit_note_rounded,
    this.prefixIcon,
    this.confirmText = 'common.save',
    this.cancelText = 'common.cancel',
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofocus = true,
    this.allowEmpty = false,
    this.validator,
    this.asyncValidator,
  });

  final String title;
  final String? subtitle;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? exampleText;
  final IconData icon;
  final IconData? prefixIcon;
  final String confirmText;
  final String cancelText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final bool autofocus;
  final bool allowEmpty;
  final String? Function(String value)? validator;
  final Future<String?> Function(String value)? asyncValidator;

  /// Displays the dialog using [showGeneralDialog] with frosted glass blur and scale animation.
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? initialValue,
    String? labelText,
    String? hintText,
    String? helperText,
    String? exampleText,
    IconData icon = Icons.edit_note_rounded,
    IconData? prefixIcon,
    String confirmText = 'common.save',
    String cancelText = 'common.cancel',
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int minLines = 1,
    int maxLines = 1,
    bool autofocus = true,
    bool allowEmpty = false,
    String? Function(String value)? validator,
    Future<String?> Function(String value)? asyncValidator,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title.trOrSelf,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AppInputDialog(
          title: title,
          subtitle: subtitle,
          initialValue: initialValue,
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          exampleText: exampleText,
          icon: icon,
          prefixIcon: prefixIcon,
          confirmText: confirmText,
          cancelText: cancelText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          minLines: minLines,
          maxLines: maxLines,
          autofocus: autofocus,
          allowEmpty: allowEmpty,
          validator: validator,
          asyncValidator: asyncValidator,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();
}

class _AppInputDialogState extends State<AppInputDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _validationError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final trimmed = _controller.text.trim();
    if (!widget.allowEmpty && trimmed.isEmpty) {
      setState(() {
        _validationError = 'This field cannot be empty.'.tr;
      });
      _focusNode.requestFocus();
      return;
    }

    if (widget.validator != null) {
      final error = widget.validator!(trimmed);
      if (error != null) {
        setState(() {
          _validationError = error.trOrSelf;
        });
        _focusNode.requestFocus();
        return;
      }
    }

    if (widget.asyncValidator != null) {
      setState(() {
        _isSaving = true;
        _validationError = null;
      });
      try {
        final error = await widget.asyncValidator!(trimmed);
        if (!mounted) return;
        if (error != null) {
          setState(() {
            _validationError = error.trOrSelf;
            _isSaving = false;
          });
          _focusNode.requestFocus();
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _validationError = '$e';
          _isSaving = false;
        });
        _focusNode.requestFocus();
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const SizedBox.expand(),
            ),
            SafeArea(
              minimum: const EdgeInsets.all(22),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 424),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
                      decoration: BoxDecoration(
                        color: context.appElevatedSurface,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: context.appElevatedSurface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: AppColors.primaryGreen,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.title.trOrSelf,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.subtitle != null &&
                              widget.subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.subtitle!.trOrSelf,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: widget.autofocus,
                            enabled: !_isSaving,
                            keyboardType: widget.keyboardType,
                            textCapitalization: widget.textCapitalization,
                            inputFormatters: widget.inputFormatters,
                            maxLength: widget.maxLength,
                            minLines: widget.minLines,
                            maxLines: widget.maxLines,
                            onChanged: (_) {
                              if (_validationError != null) {
                                setState(() {
                                  _validationError = null;
                                });
                              }
                            },
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText:
                                  widget.labelText?.trOrSelf ??
                                  widget.title.trOrSelf,
                              hintText: widget.hintText?.trOrSelf,
                              helperText: widget.helperText?.trOrSelf,
                              alignLabelWithHint: widget.maxLines > 1,
                              prefixIcon:
                                  widget.prefixIcon != null
                                      ? Padding(
                                        padding:
                                            widget.maxLines > 1
                                                ? const EdgeInsets.only(
                                                  bottom: 56,
                                                )
                                                : EdgeInsets.zero,
                                        child: Icon(
                                          widget.prefixIcon,
                                          color: AppColors.primaryGreen,
                                        ),
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.appBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryGreen,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          if (widget.exampleText != null &&
                              widget.exampleText!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.exampleText!.trOrSelf,
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (_validationError != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: context.appDangerSurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _validationError!,
                                style: TextStyle(
                                  color: context.appOnDangerSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      _isSaving
                                          ? null
                                          : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                    side: BorderSide(color: context.appBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(21),
                                    ),
                                  ),
                                  child: Text(
                                    widget.cancelText.trOrSelf,
                                    style: TextStyle(
                                      color: context.appText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: AppColors.primaryGreen
                                        .withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(21),
                                    ),
                                  ),
                                  child:
                                      _isSaving
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : Text(
                                            widget.confirmText.trOrSelf,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
