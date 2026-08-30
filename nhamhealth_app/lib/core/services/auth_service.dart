import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/modules/models/auth/google_login_request.dart';
import '../../app/modules/models/auth/authenticated_user_model.dart';
import '../../app/modules/models/auth/login_request.dart';
import '../../app/modules/models/auth/login_response.dart';
import '../../app/modules/models/auth/register_request.dart';
import '../../config/api_config.dart';
import '../storage/token_storage.dart';
import 'push_notification_service.dart';

class AuthService {
  AuthService({http.Client? client, TokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage _tokenStorage;

  Future<LoginResponse> login(LoginRequest request) =>
      _authenticate('/api/v1/auth/login', request.toJson());

  Future<void> register(RegisterRequest request) async {
    await _postJson(
      '/api/v1/auth/register',
      request.toJson(),
      timeout: const Duration(seconds: 30),
    );
  }

  Future<LoginResponse> verifyRegistration({
    required String email,
    required String code,
  }) => _authenticate('/api/v1/auth/verify-registration', {
    'email': email.trim().toLowerCase(),
    'code': code,
  });

  Future<void> resendRegistrationCode(String email) async {
    await _postJson('/api/v1/auth/resend-registration-code', {
      'email': email.trim().toLowerCase(),
    }, timeout: const Duration(seconds: 30));
  }

  Future<LoginResponse> loginWithGoogle(GoogleLoginRequest request) =>
      _authenticate('/api/v1/auth/google', request.toJson());

  Future<void> requestPasswordReset(String email) async {
    await _postJson('/api/v1/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    });
  }

  Future<String> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final payload = await _postJson('/api/v1/auth/verify-reset-code', {
      'email': email.trim().toLowerCase(),
      'code': code,
    });
    final resetToken = payload['resetToken'];
    if (resetToken is! String || resetToken.isEmpty) {
      throw const AuthException('The server did not return a reset token.');
    }
    return resetToken;
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _postJson('/api/v1/auth/reset-password', {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Your session has expired. Please sign in again.',
      );
    }
    await _postJson('/api/v1/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    }, accessToken: token);
  }

  Future<void> setAppPin(String pin) async {
    await _authenticatedPost('/api/v1/auth/pin', {'pin': pin});
  }

  Future<bool> verifyAppPin(String pin) async {
    final payload = await _authenticatedPost('/api/v1/auth/pin/verify', {
      'pin': pin,
    });
    return payload['valid'] == true;
  }

  Future<void> disableAppPin() async {
    await _authenticatedPost('/api/v1/auth/pin/disable', const {});
  }

  Future<Map<String, dynamic>> _authenticatedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Your session has expired. Please sign in again.',
      );
    }
    return _postJson(path, body, accessToken: token);
  }

  Future<String?> readAccessToken() => _tokenStorage.readAccessToken();

  Future<AuthenticatedUser?> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _tokenStorage.clear();
        return null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      return AuthenticatedUser.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on Object {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await PushNotificationService.instance?.unregister();
    } on Object {
      // Logout must still succeed if the notification service is unavailable.
    }
    await _tokenStorage.clear();
  }

  Future<LoginResponse> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    final payload = await _postJson(path, body);

    final LoginResponse result;
    try {
      result = LoginResponse.fromJson(payload);
    } on Object {
      throw const AuthException('The server response is incomplete.');
    }

    try {
      await _tokenStorage.saveAccessToken(result.accessToken);
    } on Object {
      try {
        await _tokenStorage.clear();
        await _tokenStorage.saveAccessToken(result.accessToken);
      } on Object {
        throw const AuthException(
          'Signed in, but the secure session could not be saved.',
        );
      }
    }

    unawaited(PushNotificationService.instance?.syncToken());

    return result;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    String? accessToken,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final http.Response response;
    try {
      final request =
          http.Request('POST', Uri.parse('${ApiConfig.baseUrl}$path'))
            ..followRedirects = false
            ..headers.addAll(const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            })
            ..headers.addAll(
              accessToken == null
                  ? const <String, String>{}
                  : {'Authorization': 'Bearer $accessToken'},
            )
            ..body = jsonEncode(body);
      final streamedResponse = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamedResponse);
    } on TimeoutException {
      throw const AuthException(
        'Could not reach the NhamHealth server in time. Check that the API is running and that this phone is on the same network.',
      );
    } on http.ClientException {
      throw const AuthException(
        'Could not connect to the server. Check that the API is running.',
      );
    }

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    } on Object {
      payload = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (accessToken != null &&
          (response.statusCode == 401 || response.statusCode == 403)) {
        await _tokenStorage.clear();
      }
      throw AuthException(
        _errorMessage(response, payload),
        statusCode: response.statusCode,
      );
    }

    if (payload == null) {
      throw AuthException(
        'The API returned HTTP ${response.statusCode}, but its response was not '
        'valid JSON. Restart the API and try again.',
        statusCode: response.statusCode,
      );
    }

    return payload;
  }

  String _errorMessage(http.Response response, Map<String, dynamic>? payload) {
    final apiMessage = payload?['message'] ?? payload?['error'];
    if (apiMessage is String && apiMessage.trim().isNotEmpty) {
      return apiMessage.trim();
    }

    return switch (response.statusCode) {
      301 || 302 || 303 || 307 || 308 =>
        'The API redirected the sign-in request to a web page. Restart the API '
            'and verify API_BASE_URL (${ApiConfig.baseUrl}).',
      400 => 'The sign-in request was rejected by the server.',
      401 => 'Invalid email or password.',
      403 => 'This account is not allowed to sign in to the mobile app.',
      404 =>
        'The sign-in endpoint was not found. Verify API_BASE_URL '
            '(${ApiConfig.baseUrl}).',
      500 => 'The server could not complete sign in. Check the API logs.',
      502 || 503 || 504 =>
        'The authentication service is temporarily unavailable. Try again '
            'shortly.',
      _ => 'Authentication failed (HTTP ${response.statusCode}).',
    };
  }
}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
