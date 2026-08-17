import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    // If API_BASE_URL was provided when running Flutter,
    // always use that value.
    if (_configuredBaseUrl.isNotEmpty) {
      return _withoutTrailingSlash(_configuredBaseUrl);
    }

    // Flutter Web
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    return switch (defaultTargetPlatform) {
      // Android Emulator -> access laptop localhost
      TargetPlatform.android => 'http://10.0.2.2:8080',

      // Windows/Desktop
      TargetPlatform.windows => 'http://localhost:8080',

      // Other platforms
      _ => 'http://localhost:8080',
    };
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/')
        ? value.substring(0, value.length - 1)
        : value;
  }
}
