import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/config/api_config.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';
import 'package:nhamhealth_flutter/core/services/authenticated_http_client.dart';
import 'package:nhamhealth_flutter/core/storage/token_storage.dart';

class _FakeTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

void main() {
  test('attaches stored access token to API request when missing', () async {
    final storage = _FakeTokenStorage()
      ..accessToken = 'initial-token';

    final innerClient = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer initial-token');
      return http.Response('{"ok": true}', 200);
    });

    final authService = AuthService(
      client: innerClient,
      tokenStorage: storage,
    );

    final client = AuthenticatedHttpClient(
      authService: authService,
      innerClient: innerClient,
    );

    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/dashboard'),
    );

    expect(response.statusCode, 200);
  });

  test('does not attach authorization to auth endpoints', () async {
    final storage = _FakeTokenStorage()..accessToken = 'some-token';

    final innerClient = MockClient((request) async {
      expect(request.headers.containsKey('Authorization'), isFalse);
      return http.Response('{"status": "ok"}', 200);
    });

    final authService = AuthService(
      client: innerClient,
      tokenStorage: storage,
    );

    final client = AuthenticatedHttpClient(
      authService: authService,
      innerClient: innerClient,
    );

    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/login'),
    );

    expect(response.statusCode, 200);
  });

  test('transparently refreshes token on 401 and replays the request', () async {
    final storage = _FakeTokenStorage()
      ..accessToken = 'expired-token'
      ..refreshToken = 'valid-refresh-token';

    var dashboardAttempts = 0;
    var refreshCalled = false;

    final innerClient = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/refresh') {
        refreshCalled = true;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['refreshToken'], 'valid-refresh-token');
        return http.Response(
          jsonEncode({
            'accessToken': 'new-fresh-token',
            'tokenType': 'Bearer',
            'expiresIn': 3600,
            'refreshToken': 'new-refresh-token',
            'refreshExpiresIn': 2592000,
            'user': {
              'userId': 1,
              'email': 'user@example.com',
            },
          }),
          200,
        );
      }

      if (request.url.path == '/api/v1/users/me/dashboard') {
        dashboardAttempts++;
        if (dashboardAttempts == 1) {
          expect(request.headers['Authorization'], 'Bearer expired-token');
          return http.Response('{"message": "Unauthorized"}', 401);
        } else {
          expect(request.headers['Authorization'], 'Bearer new-fresh-token');
          return http.Response('{"fullName": "Sokha"}', 200);
        }
      }

      return http.Response('Not Found', 404);
    });

    final authService = AuthService(
      client: innerClient,
      tokenStorage: storage,
    );

    final client = AuthenticatedHttpClient(
      authService: authService,
      innerClient: innerClient,
    );

    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/dashboard'),
      headers: {'Authorization': 'Bearer expired-token'},
    );

    expect(response.statusCode, 200);
    expect(jsonDecode(response.body)['fullName'], 'Sokha');
    expect(dashboardAttempts, 2);
    expect(refreshCalled, isTrue);
    expect(storage.accessToken, 'new-fresh-token');
  });

  test('returns 401 when token refresh fails without crashing', () async {
    final storage = _FakeTokenStorage()
      ..accessToken = 'expired-token'
      ..refreshToken = 'invalid-refresh-token';

    final innerClient = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/refresh') {
        return http.Response('{"message": "Refresh token expired"}', 401);
      }
      return http.Response('{"message": "Unauthorized"}', 401);
    });

    final authService = AuthService(
      client: innerClient,
      tokenStorage: storage,
    );

    final client = AuthenticatedHttpClient(
      authService: authService,
      innerClient: innerClient,
    );

    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/dashboard'),
      headers: {'Authorization': 'Bearer expired-token'},
    );

    expect(response.statusCode, 401);
  });
}
