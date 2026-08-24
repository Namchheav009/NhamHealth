import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

typedef PinValidator = Future<String?> Function(String pin);
typedef BiometricAuthenticator = Future<bool> Function();

const _pinLength = 6;

Future<String?> showPinKeypadDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  bool confirmPin = false,
  PinValidator? validator,
  BiometricAuthenticator? biometricAuthenticator,
  String biometricLabel = 'Use biometrics',
  IconData biometricIcon = Icons.fingerprint_rounded,
  bool allowCancel = true,
}) => showGeneralDialog<String>(
  context: context,
  barrierDismissible: false,
  barrierLabel: 'PIN entry',
  barrierColor: Colors.black.withValues(alpha: .18),
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder:
      (context, animation, secondaryAnimation) => _PinKeypadDialog(
        title: title,
        subtitle: subtitle,
        confirmPin: confirmPin,
        validator: validator,
        biometricAuthenticator: biometricAuthenticator,
        biometricLabel: biometricLabel,
        biometricIcon: biometricIcon,
        allowCancel: allowCancel,
      ),
  transitionBuilder:
      (context, animation, secondaryAnimation, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
);

class _PinKeypadDialog extends StatefulWidget {
  const _PinKeypadDialog({
    required this.title,
    this.subtitle,
    required this.confirmPin,
    this.validator,
    this.biometricAuthenticator,
    required this.biometricLabel,
    required this.biometricIcon,
    required this.allowCancel,
  });

  final String title;
  final String? subtitle;
  final bool confirmPin;
  final PinValidator? validator;
  final BiometricAuthenticator? biometricAuthenticator;
  final String biometricLabel;
  final IconData biometricIcon;
  final bool allowCancel;

  @override
  State<_PinKeypadDialog> createState() => _PinKeypadDialogState();
}

class _PinKeypadDialogState extends State<_PinKeypadDialog> {
  String _pin = '';
  String? _firstPin;
  String? _error;
  bool _busy = false;

  bool get _confirming => _firstPin != null;

  Future<void> _addDigit(String digit) async {
    if (_busy || _pin.length == _pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == _pinLength) await _submit();
  }

  Future<void> _submit() async {
    final enteredPin = _pin;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    if (widget.confirmPin && !_confirming) {
      setState(() {
        _firstPin = enteredPin;
        _pin = '';
      });
      return;
    }
    if (_confirming && enteredPin != _firstPin) {
      setState(() {
        _pin = '';
        _error = 'PINs do not match. Try again.';
      });
      return;
    }

    setState(() => _busy = true);
    String? error;
    try {
      error = await widget.validator?.call(enteredPin);
    } on Object {
      error = 'Could not verify your PIN. Check your connection and retry.';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(enteredPin);
    } else {
      setState(() {
        _busy = false;
        _pin = '';
        _error = error;
      });
    }
  }

  void _removeDigit() {
    if (_busy || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _authenticateBiometrically() async {
    if (_busy || widget.biometricAuthenticator == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final authenticated = await widget.biometricAuthenticator!();
    if (!mounted) return;
    if (authenticated) {
      Navigator.of(context).pop('biometric');
    } else {
      setState(() {
        _busy = false;
        _error = 'Biometric check was not completed. Use your PIN or retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.allowCancel,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
      child: SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 680),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface.withValues(alpha: .88),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: .8)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkGreen.withValues(alpha: .16),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: Text(
                              _confirming ? 'Confirm PIN'.tr : widget.title.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.allowCancel)
                            IconButton(
                              tooltip: 'Cancel'.tr,
                              onPressed:
                                  _busy ? null : () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              color: AppColors.secondaryText,
                            )
                          else
                            const SizedBox(width: 40),
                        ],
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _confirming
                              ? 'Enter the same 6 digits again'.tr
                              : widget.subtitle!.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Semantics(
                        label: '@count of 6 PIN digits entered'.trParams({
                          'count': '${_pin.length}',
                        }),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pinLength,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 13,
                              height: 13,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    index < _pin.length
                                        ? AppColors.primaryGreen
                                        : Colors.transparent,
                                border: Border.all(
                                  color:
                                      index < _pin.length
                                          ? AppColors.primaryGreen
                                          : AppColors.navigationGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child:
                            _error == null
                                ? null
                                : Center(
                                  child: Text(
                                    _error!.tr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.errorCoral,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                      ),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: AppColors.primaryGreen,
                            backgroundColor: AppColors.softGreen,
                          ),
                        ),
                      _keypad(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _keypad() {
    const keys = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var column = 0; column < 3; column++)
                _numberKey(keys[row * 3 + column]),
            ],
          ),
          if (row < 2) const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child:
                  widget.biometricAuthenticator == null
                      ? null
                      : IconButton(
                        tooltip: widget.biometricLabel.tr,
                        onPressed: _busy ? null : _authenticateBiometrically,
                        icon: Icon(widget.biometricIcon, size: 32),
                        color: AppColors.primaryGreen,
                      ),
            ),
            _numberKey('0'),
            SizedBox(
              width: 70,
              height: 70,
              child: IconButton(
                tooltip: 'Delete digit'.tr,
                onPressed: _pin.isEmpty ? null : _removeDigit,
                icon: const Icon(Icons.backspace_outlined),
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberKey(String number) => SizedBox(
    width: 70,
    height: 70,
    child: OutlinedButton(
      onPressed: _busy ? null : () => _addDigit(number),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: AppColors.darkGreen,
        backgroundColor: Colors.white.withValues(alpha: .46),
        side: const BorderSide(color: AppColors.navigationGreen, width: 1.4),
        shape: const CircleBorder(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w300),
          ),
          if (_letters[number] case final letters?)
            Text(
              letters,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                height: .8,
              ),
            ),
        ],
      ),
    ),
  );

  static const _letters = <String, String>{
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };
}
