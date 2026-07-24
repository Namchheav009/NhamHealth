import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/api_health.dart';
import 'health_api.dart';

class ApiService implements HealthApi {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  String get baseUrl => ApiConfig.baseUrl;

  @override
  Future<ApiHealth> getHealth() async {
    final uri = Uri.parse('$baseUrl/api/v1/health');
    final response = await _client.get(uri, headers: const {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'The server returned HTTP ${response.statusCode}.',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiHealth.fromJson(json);
    } on FormatException catch (error) {
      throw ApiException('The server returned invalid JSON.', error);
    } on TypeError catch (error) {
      throw ApiException('The server response has an unexpected shape.', error);
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
