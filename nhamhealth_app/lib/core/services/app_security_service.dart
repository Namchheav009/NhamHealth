import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppSecurityService {
  AppSecurityService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuthentication,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _localAuth = localAuthentication ?? LocalAuthentication();

  static const _pinHashKey = 'privacy_pin_hash';
  static const _biometricsKey = 'privacy_biometrics_enabled';
  static const _setupPromptPrefix = 'privacy_setup_prompted_';
  static const _setupPendingPrefix = 'privacy_setup_pending_';
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  String? _pinHashCache;
  bool _pinStateLoaded = false;
  bool? _biometricsEnabledCache;
  bool? _biometricsAvailableCache;

  Future<bool> get hasPin async {
    if (!_pinStateLoaded) {
      _pinHashCache = await _storage.read(key: _pinHashKey);
      _pinStateLoaded = true;
    }
    return _pinHashCache != null;
  }

  Future<bool> get biometricsEnabled async =>
      _biometricsEnabledCache ??=
          await _storage.read(key: _biometricsKey) == 'true';

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const FormatException('PIN must contain exactly 4 digits.');
    }
    await _storage.write(key: _pinHashKey, value: _hash(pin));
    _pinHashCache = _hash(pin);
    _pinStateLoaded = true;
  }

  Future<bool> verifyPin(String pin) async {
    await hasPin;
    final saved = _pinHashCache;
    return saved != null && saved == _hash(pin);
  }

  Future<bool> canUseBiometrics() async {
    if (_biometricsAvailableCache case final cached?) return cached;
    try {
      return _biometricsAvailableCache =
          await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics &&
          (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } on Object {
      return _biometricsAvailableCache = false;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    if (enabled && !await canUseBiometrics()) {
      throw StateError('Biometric authentication is not available.');
    }
    await _storage.write(key: _biometricsKey, value: enabled.toString());
    _biometricsEnabledCache = enabled;
  }

  Future<bool> authenticateBiometrically(String reason) async {
    if (!await biometricsEnabled || !await canUseBiometrics()) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on Object {
      return false;
    }
  }

  Future<void> disable() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _biometricsKey);
    _pinHashCache = null;
    _pinStateLoaded = true;
    _biometricsEnabledCache = false;
  }

  Future<bool> wasSetupPromptedFor(int userId) async =>
      await _storage.read(key: '$_setupPromptPrefix$userId') == 'true';

  Future<void> markSetupPromptedFor(int userId) =>
      _storage.write(key: '$_setupPromptPrefix$userId', value: 'true');

  Future<void> markSetupPendingFor(int userId) =>
      _storage.write(key: '$_setupPendingPrefix$userId', value: 'true');

  Future<bool> isSetupPendingFor(int userId) async =>
      await _storage.read(key: '$_setupPendingPrefix$userId') == 'true';

  Future<void> clearSetupPendingFor(int userId) =>
      _storage.delete(key: '$_setupPendingPrefix$userId');

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();
}
