import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl returns default URL without throwing', () {
      final url = ApiConfig.baseUrl;
      expect(url, isNotEmpty);
      expect(url.startsWith('http'), isTrue);
      expect(url.endsWith('/'), isFalse);
    });

    test('withoutTrailingSlash removes trailing slashes', () {
      expect(
        ApiConfig.withoutTrailingSlash('https://nhamhealth.onrender.com/'),
        'https://nhamhealth.onrender.com',
      );
      expect(
        ApiConfig.withoutTrailingSlash('https://nhamhealth.onrender.com'),
        'https://nhamhealth.onrender.com',
      );
      expect(
        ApiConfig.withoutTrailingSlash('http://localhost:8080/'),
        'http://localhost:8080',
      );
    });
  });
}

