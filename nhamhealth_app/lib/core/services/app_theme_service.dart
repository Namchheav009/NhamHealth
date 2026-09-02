import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppThemeService {
  AppThemeService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const fallbackThemeMode = ThemeMode.system;
  static const _themeModeKey = 'app_theme_mode';

  final FlutterSecureStorage _storage;

  ThemeMode _themeMode = fallbackThemeMode;

  ThemeMode get themeMode => _themeMode;

  Future<ThemeMode> loadThemeMode() async {
    try {
      _themeMode = themeModeForValue(await _storage.read(key: _themeModeKey));
    } on Object {
      _themeMode = fallbackThemeMode;
    }
    return _themeMode;
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    try {
      await _storage.write(key: _themeModeKey, value: themeMode.name);
    } on Object {
      // The selected theme still works when secure storage is unavailable.
    }
  }

  static ThemeMode themeModeForValue(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => fallbackThemeMode,
    );
  }
}
