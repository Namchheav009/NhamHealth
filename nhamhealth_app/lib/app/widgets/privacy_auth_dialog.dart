import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/app_security_service.dart';
import 'pin_keypad_dialog.dart';

class PrivacyAuth {
  PrivacyAuth._();

  static Future<bool> require({
    required String reason,
    bool allowCancel = true,
  }) async {
    final security = Get.find<AppSecurityService>();
    if (!await security.hasPin) return true;
    if (await security.authenticateBiometrically(reason.tr)) return true;
    final biometricsEnabled = await security.biometricsEnabled;
    final canUseBiometrics =
        biometricsEnabled && await security.canUseBiometrics();
    final biometricKind = await security.biometricKind;
    final biometricLabel = switch (biometricKind) {
      AppBiometricKind.face => 'Use Face ID',
      AppBiometricKind.fingerprint => 'Use fingerprint',
      AppBiometricKind.generic => 'Use biometrics',
    };
    final pin = await showPinKeypadDialog(
      context: Get.context!,
      title: 'Enter PIN',
      subtitle: reason,
      validator: (pin) async {
        if (await security.verifyPin(pin)) return null;
        return 'Incorrect PIN. Please try again.';
      },
      biometricAuthenticator:
          canUseBiometrics
              ? () => security.authenticateBiometrically(reason.tr)
              : null,
      biometricLabel: biometricLabel,
      biometricIcon:
          biometricKind == AppBiometricKind.face
              ? Icons.face_rounded
              : Icons.fingerprint_rounded,
      allowCancel: allowCancel,
    );
    return pin != null;
  }
}
