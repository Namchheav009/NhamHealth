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
  Future<LoginResponse>? _refreshInFlight;

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

  Future<LoginResponse> verifyLogin({
    required String email,
    required String code,
  }) => _authenticate('/api/v1/auth/verify-login', {
    'email': email.trim().toLowerCase(),
    'code': code,
  });

  Future<void> resendLoginCode(String email) async {
    await _postJson('/api/v1/auth/resend-login-code', {
      'email': email.trim().toLowerCase(),
    }, timeout: const Duration(seconds: 30));
  }

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
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();
    var serverLogoutCompleted = false;

    // Mark the account as logged out using the access token first. This also
    // supports sessions created before refresh tokens were introduced.
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        await _postJson(
          '/api/v1/auth/logout-all',
          const {},
          accessToken: accessToken,
          allowRefresh: false,
        );
        serverLogoutCompleted = true;
      } on Object {
        // Local sign-out must still complete while the API is unavailable.
      }
    }

    // Fall back to refresh-token logout when the access token has expired.
    if (!serverLogoutCompleted &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      try {
        await _postJson('/api/v1/auth/logout', {
          'refreshToken': refreshToken,
        }, allowRefresh: false);
      } on Object {
        // Local sign-out must still complete while the API is unavailable.
      }
    }
    await _tokenStorage.clear();
  }

  Future<LoginResponse> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    final payload = await _postJson(path, body);

    if (payload['otpRequired'] == true) {
      final email = payload['email'];
      throw LoginOtpRequiredException(email is String ? email : '');
    }

    final LoginResponse result;
    try {
      result = LoginResponse.fromJson(payload);
    } on Object {
      throw const AuthException('The server response is incomplete.');
    }

    try {
      await _tokenStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
    } on Object {
      try {
        await _tokenStorage.clear();
        await _tokenStorage.saveTokens(
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
        );
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
    bool allowRefresh = true,
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
      final storedRefreshToken = await _tokenStorage.readRefreshToken();
      if (accessToken != null &&
          response.statusCode == 401 &&
          allowRefresh &&
          storedRefreshToken != null &&
          storedRefreshToken.isNotEmpty) {
        final refreshed = await _refreshOnce();
        return _postJson(
          path,
          body,
          accessToken: refreshed.accessToken,
          timeout: timeout,
          allowRefresh: false,
        );
      }
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

  Future<LoginResponse> _refreshOnce() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<LoginResponse> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStorage.clear();
      throw const AuthException(
        'Your session has expired. Please sign in again.',
      );
    }
    try {
      final payload = await _postJson('/api/v1/auth/refresh', {
        'refreshToken': refreshToken,
      }, allowRefresh: false);
      final response = LoginResponse.fromJson(payload);
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return response;
    } on Object {
      await _tokenStorage.clear();
      rethrow;
    }
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

class LoginOtpRequiredException extends AuthException {
  const LoginOtpRequiredException(this.email)
    : super('A login verification code was sent to your email.');

  final String email;
}
