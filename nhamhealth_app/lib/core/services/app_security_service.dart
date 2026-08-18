import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_service.dart';

enum AppBiometricKind { fingerprint, face, generic }

class AppSecurityService {
  AppSecurityService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuthentication,
    AuthService? authService,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _localAuth = localAuthentication ?? LocalAuthentication(),
       _authService = authService ?? AuthService();

  static const _pinHashKey = 'privacy_pin_hash';
  static const _biometricsKey = 'privacy_biometrics_enabled';
  static const _setupPromptPrefix = 'privacy_setup_prompted_';
  static const _setupPendingPrefix = 'privacy_setup_pending_';
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final AuthService _authService;
  String? _pinHashCache;
  bool _pinStateLoaded = false;
  bool? _serverHasPin;
  bool? _biometricsEnabledCache;
  bool? _biometricsAvailableCache;
  AppBiometricKind? _biometricKindCache;

  Future<bool> get hasPin async {
    if (_serverHasPin case final serverValue?) return serverValue;
    if (!_pinStateLoaded) {
      _pinHashCache = await _storage.read(key: _pinHashKey);
      _pinStateLoaded = true;
    }
    return _pinHashCache != null;
  }

  void syncPinState(bool hasPin) {
    _serverHasPin = hasPin;
    if (!hasPin) {
      _pinHashCache = null;
      _pinStateLoaded = true;
    }
  }

  Future<bool> get biometricsEnabled async =>
      _biometricsEnabledCache ??=
          await _storage.read(key: _biometricsKey) == 'true';

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw const FormatException('PIN must contain exactly 6 digits.');
    }
    await _authService.setAppPin(pin);
    await _storage.write(key: _pinHashKey, value: _hash(pin));
    _pinHashCache = _hash(pin);
    _pinStateLoaded = true;
    _serverHasPin = true;
  }

  Future<bool> verifyPin(String pin) async {
    final valid = await _authService.verifyAppPin(pin);
    if (valid) {
      await _storage.write(key: _pinHashKey, value: _hash(pin));
      _pinHashCache = _hash(pin);
      _pinStateLoaded = true;
    }
    return valid;
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

  Future<AppBiometricKind> get biometricKind async {
    if (_biometricKindCache case final cached?) return cached;
    try {
      final available = await _localAuth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) {
        return _biometricKindCache = AppBiometricKind.face;
      }
      if (available.contains(BiometricType.fingerprint)) {
        return _biometricKindCache = AppBiometricKind.fingerprint;
      }
    } on Object {
      // The generic label is a safe fallback when the platform cannot report a
      // specific biometric sensor type.
    }
    return _biometricKindCache = AppBiometricKind.generic;
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
    return confirmDeviceBiometrics(reason);
  }

  /// Authenticates against the device sensor without requiring the app-level
  /// biometric preference to already be enabled. Used during first-time setup.
  Future<bool> confirmDeviceBiometrics(String reason) async {
    if (!await canUseBiometrics()) return false;
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
    await _authService.disableAppPin();
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _biometricsKey);
    _pinHashCache = null;
    _pinStateLoaded = true;
    _serverHasPin = false;
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
