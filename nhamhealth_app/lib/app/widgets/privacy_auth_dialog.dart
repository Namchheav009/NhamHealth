import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/services/app_security_service.dart';

class PrivacyAuth {
  PrivacyAuth._();

  static Future<bool> require({required String reason}) async {
    final security = Get.find<AppSecurityService>();
    if (!await security.hasPin) return true;
    if (await security.authenticateBiometrically(reason)) return true;
    return await Get.dialog<bool>(
          _PinDialog(reason: reason, security: security),
          barrierDismissible: false,
        ) ??
        false;
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.reason, required this.security});
  final String reason;
  final AppSecurityService security;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _unlock() async {
    if (_controller.text.length != 4 || _busy) return;
    setState(() => _busy = true);
    final valid = await widget.security.verifyPin(_controller.text);
    if (!mounted) return;
    if (valid) {
      Navigator.of(context).pop(true);
    } else {
      _controller.clear();
      setState(() {
        _busy = false;
        _error = 'Incorrect PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.lock_rounded, color: Color(0xFF009B43), size: 34),
    title: const Text('Privacy check'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.reason, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        TextField(
          controller: _controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '4-digit PIN',
            counterText: '',
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _unlock(),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
      FilledButton(onPressed: _busy ? null : _unlock, child: const Text('Unlock')),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
