import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _withoutTrailingSlash(_configuredBaseUrl);
    }

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    return switch (defaultTargetPlatform) {
      // Android development uses an ADB reverse tunnel so the same URL works
      // reliably on a USB-connected emulator or physical device.
      TargetPlatform.android => 'http://127.0.0.1:8080',
      _ => 'http://localhost:8080',
    };
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
