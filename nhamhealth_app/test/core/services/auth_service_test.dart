import 'package:nhamhealth_flutter/app/modules/models/auth/google_login_request.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/login_request.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/register_request.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';
import 'package:nhamhealth_flutter/core/storage/token_storage.dart';

void main() {
  test(
    'new Google user requires registration OTP without storing tokens',
    () async {
      final storage = _MemoryTokenStorage();
      final service = AuthService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/google');
          return http.Response(
            jsonEncode({
              'otpRequired': true,
              'purpose': 'registration',
              'email': 'new@example.com',
            }),
            202,
          );
        }),
        tokenStorage: storage,
      );
      await expectLater(
        service.loginWithGoogle(
          const GoogleLoginRequest(idToken: 'google-token'),
        ),
        throwsA(
          isA<RegistrationOtpRequiredException>().having(
            (error) => error.email,
            'email',
            'new@example.com',
          ),
        ),
      );
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    },
  );

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
            'refreshToken': 'refresh-token',
            'refreshExpiresIn': 2592000,
            'user': {
              'userId': 7,
              'email': 'user@example.com',
              'role': 'USER',
              'fullName': 'Nham User',
              'profileImageUrl': '/uploads/profile-images/user.png',
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
    expect(response.user.displayName, 'Nham User');
    expect(response.user.profileImageUrl, '/uploads/profile-images/user.png');
    expect(storage.accessToken, 'access-token');
    expect(storage.refreshToken, 'refresh-token');
  });

  test(
    'registration exposes conflict status for an existing account',
    () async {
      final service = AuthService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': 'An account with this email already exists',
            }),
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
    },
  );

  test('login does not follow a redirect to the HTML login page', () async {
    final service = AuthService(
      client: MockClient((request) async {
        expect(request.followRedirects, isFalse);
        return http.Response(
          '<html><body>Sign in</body></html>',
          302,
          headers: {'location': '/login'},
        );
      }),
      tokenStorage: _MemoryTokenStorage(),
    );

    await expectLater(
      service.login(
        const LoginRequest(
          email: 'user@example.com',
          password: 'StrongPass123!',
        ),
      ),
      throwsA(
        isA<AuthException>()
            .having((error) => error.statusCode, 'statusCode', 302)
            .having(
              (error) => error.message,
              'message',
              contains('redirected the sign-in request'),
            ),
      ),
    );
  });

  test('login explains a non-JSON service error', () async {
    final service = AuthService(
      client: MockClient(
        (_) async => http.Response('<html>Database unavailable</html>', 503),
      ),
      tokenStorage: _MemoryTokenStorage(),
    );

    await expectLater(
      service.login(
        const LoginRequest(
          email: 'user@example.com',
          password: 'StrongPass123!',
        ),
      ),
      throwsA(
        isA<AuthException>()
            .having((error) => error.statusCode, 'statusCode', 503)
            .having(
              (error) => error.message,
              'message',
              contains('temporarily unavailable'),
            ),
      ),
    );
  });

  test(
    'login surfaces the server OTP challenge without storing tokens',
    () async {
      final storage = _MemoryTokenStorage();
      final service = AuthService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'otpRequired': true,
              'email': 'user@example.com',
              'message': 'A login verification code was sent to your email',
            }),
            202,
          ),
        ),
        tokenStorage: storage,
      );

      await expectLater(
        service.login(
          const LoginRequest(
            email: 'user@example.com',
            password: 'StrongPass123!',
          ),
        ),
        throwsA(
          isA<LoginOtpRequiredException>().having(
            (error) => error.email,
            'email',
            'user@example.com',
          ),
        ),
      );
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    },
  );

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
            'fullName': 'Nham User',
            'profileImageUrl': null,
          }),
          200,
        );
      }),
      tokenStorage: storage,
    );

    final user = await service.restoreSession();

    expect(user?.email, 'user@example.com');
    expect(user?.displayName, 'Nham User');
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

  test('restoreSession refreshes an expired access token', () async {
    final storage = _MemoryTokenStorage()
      ..accessToken = 'expired-token'
      ..refreshToken = 'saved-refresh-token';
    var step = 0;
    final service = AuthService(
      client: MockClient((request) async {
        step++;
        if (step == 1) {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/auth/me');
          expect(request.headers['Authorization'], 'Bearer expired-token');
          return http.Response('', 401);
        }
        if (step == 2) {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/auth/refresh');
          expect(
            jsonDecode(request.body),
            {'refreshToken': 'saved-refresh-token'},
          );
          return http.Response(
            jsonEncode({
              'accessToken': 'new-access-token',
              'refreshToken': 'new-refresh-token',
              'tokenType': 'Bearer',
              'expiresIn': 86400,
              'user': {
                'userId': 7,
                'email': 'user@example.com',
                'role': 'USER',
                'fullName': 'Nham User',
                'profileImageUrl': null,
              },
            }),
            200,
          );
        }

        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/auth/me');
        expect(request.headers['Authorization'], 'Bearer new-access-token');
        return http.Response(
          jsonEncode({
            'userId': 7,
            'email': 'user@example.com',
            'role': 'USER',
            'fullName': 'Nham User',
            'profileImageUrl': null,
          }),
          200,
        );
      }),
      tokenStorage: storage,
    );

    final user = await service.restoreSession();

    expect(step, 3);
    expect(user?.email, 'user@example.com');
    expect(storage.accessToken, 'new-access-token');
    expect(storage.refreshToken, 'new-refresh-token');
  });

  test('logout marks an access-token-only session on the server', () async {
    final storage = _MemoryTokenStorage()..accessToken = 'saved-token';
    final service = AuthService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/logout-all');
        expect(request.headers['Authorization'], 'Bearer saved-token');
        expect(jsonDecode(request.body), <String, dynamic>{});
        return http.Response(
          jsonEncode({'message': 'Signed out on all devices'}),
          200,
        );
      }),
      tokenStorage: storage,
    );

    await service.logout();

    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test('authenticated PIN request clears a stale rejected token', () async {
    final storage = _MemoryTokenStorage()..accessToken = 'stale-token';
    final service = AuthService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/pin');
        expect(request.headers['Authorization'], 'Bearer stale-token');
        return http.Response(
          jsonEncode({
            'message': 'Your session is no longer valid. Please sign in again.',
          }),
          401,
        );
      }),
      tokenStorage: storage,
    );

    await expectLater(
      service.setAppPin('258025'),
      throwsA(
        isA<AuthException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having(
              (error) => error.message,
              'message',
              'Your session is no longer valid. Please sign in again.',
            ),
      ),
    );
    expect(storage.accessToken, isNull);
  });

  test('password reset calls all three public API endpoints', () async {
    var step = 0;
    final service = AuthService(
      client: MockClient((request) async {
        step++;
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        if (step == 1) {
          expect(request.url.path, '/api/v1/auth/forgot-password');
          expect(body, {'email': 'user@example.com'});
          return http.Response(jsonEncode({'message': 'Code sent'}), 202);
        }
        if (step == 2) {
          expect(request.url.path, '/api/v1/auth/verify-reset-code');
          expect(body, {'email': 'user@example.com', 'code': '123456'});
          return http.Response(
            jsonEncode({'resetToken': 'one-time-token', 'expiresIn': 900}),
            200,
          );
        }
        expect(request.url.path, '/api/v1/auth/reset-password');
        expect(body, {
          'resetToken': 'one-time-token',
          'newPassword': 'NewPassword123!',
        });
        return http.Response(
          jsonEncode({
            'accessToken': 'new-access-token',
            'tokenType': 'Bearer',
            'expiresIn': 900,
            'refreshToken': 'new-refresh-token',
            'refreshExpiresIn': 2592000,
            'user': {
              'id': 1,
              'email': 'user@example.com',
              'role': 'USER',
            },
          }),
          200,
        );
      }),
      tokenStorage: _MemoryTokenStorage(),
    );

    await service.requestPasswordReset(' USER@example.com ');
    final resetToken = await service.verifyPasswordResetCode(
      email: 'user@example.com',
      code: '123456',
    );
    await service.resetPassword(
      resetToken: resetToken,
      newPassword: 'NewPassword123!',
    );

    expect(resetToken, 'one-time-token');
    expect(step, 3);
  });

  test('password reset surfaces API verification errors', () async {
    final service = AuthService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'The verification code is incorrect'}),
          400,
        ),
      ),
      tokenStorage: _MemoryTokenStorage(),
    );

    await expectLater(
      service.verifyPasswordResetCode(
        email: 'user@example.com',
        code: '000000',
      ),
      throwsA(
        isA<AuthException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having(
              (error) => error.message,
              'message',
              'The verification code is incorrect',
            ),
      ),
    );
  });

  test('login surfaces unverified account error with 403 status', () async {
    final service = AuthService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message':
                'Account is not verified. Please verify your email or phone number before signing in.',
          }),
          403,
        ),
      ),
      tokenStorage: _MemoryTokenStorage(),
    );

    await expectLater(
      service.login(
        const LoginRequest(email: 'user@example.com', password: 'Password123!'),
      ),
      throwsA(
        isA<AuthException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.message,
              'message',
              contains('Account is not verified'),
            ),
      ),
    );
  });

  test('login surfaces forbidden admin role error with 403 status', () async {
    final service = AuthService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message':
                'This account must sign in through the administration portal',
          }),
          403,
        ),
      ),
      tokenStorage: _MemoryTokenStorage(),
    );

    await expectLater(
      service.login(
        const LoginRequest(
          email: 'admin@nhamhealth.com',
          password: 'AdminPassword123!',
        ),
      ),
      throwsA(
        isA<AuthException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.message,
              'message',
              contains('administration portal'),
            ),
      ),
    );
  });

  test('login surfaces user-friendly message on network connection failure', () async {
    final service = AuthService(
      client: MockClient((_) async => throw http.ClientException('Connection reset by peer')),
      tokenStorage: _MemoryTokenStorage(),
    );

    await expectLater(
      service.login(
        const LoginRequest(email: 'user@example.com', password: 'Password123!'),
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('Unable to connect to the server'),
        ),
      ),
    );
  });

  test('login surfaces server cold-start message on timeout', () async {
    final service = AuthService(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        throw http.ClientException('ClientException with socket timeout');
      }),
      tokenStorage: _MemoryTokenStorage(),
    );

    await expectLater(
      service.login(
        const LoginRequest(email: 'user@example.com', password: 'Password123!'),
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('Unable to connect to the server'),
        ),
      ),
    );
  });
}

class _MemoryTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}
