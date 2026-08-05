import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/app/modules/auth/models/login_request.dart';
import 'package:nhamhealth_flutter/app/modules/auth/models/register_request.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';
import 'package:nhamhealth_flutter/core/storage/token_storage.dart';

void main() {
  test('login stores the access token returned by the API', () async {
    final storage = _MemoryTokenStorage();
    final service = AuthService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'password': 'StrongPass123!',
        });
        return http.Response(
          jsonEncode({
            'accessToken': 'access-token',
            'tokenType': 'Bearer',
            'expiresIn': 86400,
            'user': {
              'userId': 7,
              'email': 'user@example.com',
              'role': 'USER',
            },
          }),
          200,
        );
      }),
      tokenStorage: storage,
    );

    final response = await service.login(
      const LoginRequest(
        email: ' USER@example.com ',
        password: 'StrongPass123!',
      ),
    );

    expect(response.user.email, 'user@example.com');
    expect(storage.accessToken, 'access-token');
  });

  test('registration exposes conflict status for an existing account', () async {
    final service = AuthService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'An account with this email already exists'}),
          409,
        ),
      ),
      tokenStorage: _MemoryTokenStorage(),
    );

    await expectLater(
      service.register(
        const RegisterRequest(
          fullName: 'Existing User',
          email: 'user@example.com',
          password: 'StrongPass123!',
        ),
      ),
      throwsA(
        isA<AuthException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              'An account with this email already exists',
            ),
      ),
    );
  });

  test('restoreSession validates a saved token and returns its user', () async {
    final storage = _MemoryTokenStorage()..accessToken = 'saved-token';
    final service = AuthService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/auth/me');
        expect(request.headers['Authorization'], 'Bearer saved-token');
        return http.Response(
          jsonEncode({
            'userId': 7,
            'email': 'user@example.com',
            'role': 'USER',
          }),
          200,
        );
      }),
      tokenStorage: storage,
    );

    final user = await service.restoreSession();

    expect(user?.email, 'user@example.com');
  });

  test('restoreSession clears a rejected token', () async {
    final storage = _MemoryTokenStorage()..accessToken = 'expired-token';
    final service = AuthService(
      client: MockClient((_) async => http.Response('', 401)),
      tokenStorage: storage,
    );

    expect(await service.restoreSession(), isNull);
    expect(storage.accessToken, isNull);
  });
}

class _MemoryTokenStorage extends TokenStorage {
  String? accessToken;

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<void> clear() async {
    accessToken = null;
  }
}
