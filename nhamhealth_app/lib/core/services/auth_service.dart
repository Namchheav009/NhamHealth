import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/modules/models/auth/authenticated_user_model.dart';
import '../../app/modules/models/auth/google_login_request.dart';
import '../../app/modules/models/auth/login_request.dart';
import '../../app/modules/models/auth/login_response.dart';
import '../../app/modules/models/auth/register_request.dart';
import '../../config/api_config.dart';
import '../storage/token_storage.dart';
import 'push_notification_service.dart';

class AuthService {
  static const _authDeliveryTimeout = Duration(seconds: 60);
  static const _emailDeliveryTimeout = Duration(seconds: 60);

  AuthService({http.Client? client, TokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage _tokenStorage;
  Future<LoginResponse>? _refreshInFlight;

  Future<LoginResponse> login(LoginRequest request) => _authenticate(
    '/api/v1/auth/login',
    request.toJson(),
    timeout: _authDeliveryTimeout,
  );

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
      _authenticate(
        '/api/v1/auth/google',
        request.toJson(),
        timeout: _emailDeliveryTimeout,
      );

  Future<void> requestPasswordReset(String email) async {
    await _postJson('/api/v1/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    }, timeout: _emailDeliveryTimeout);
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

  Future<LoginResponse> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final payload = await _postJson('/api/v1/auth/reset-password', {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
    final response = LoginResponse.fromJson(payload);
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<LoginResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Your session has expired. Please sign in again.',
      );
    }
    final payload = await _postJson('/api/v1/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    }, accessToken: token);
    final response = LoginResponse.fromJson(payload);
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
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

  Future<Map<String, dynamic>> sendPhoneVerificationCode(String phone) async {
    return _authenticatedPost('/api/v1/users/me/phone/send-code', {
      'phone': phone.trim(),
    });
  }

  Future<Map<String, dynamic>> verifyPhoneVerificationCode({
    required String phone,
    required String code,
  }) async {
    return _authenticatedPost('/api/v1/users/me/phone/verify-code', {
      'phone': phone.trim(),
      'code': code.trim(),
    });
  }

  Future<Map<String, dynamic>> sendEmailVerificationCode(String email) async {
    return _authenticatedPost('/api/v1/users/me/email/send-code', {
      'email': email.trim().toLowerCase(),
    });
  }

  Future<Map<String, dynamic>> verifyEmailVerificationCode({
    required String email,
    required String code,
  }) async {
    return _authenticatedPost('/api/v1/users/me/email/verify-code', {
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
    });
  }

  Future<Map<String, dynamic>> postAuthenticatedJson(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 15),
    bool allowRefresh = true,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Your session has expired. Please sign in again.',
      );
    }
    return _postJson(
      path,
      body,
      accessToken: token,
      timeout: timeout,
      allowRefresh: allowRefresh,
    );
  }

  Future<Map<String, dynamic>> _authenticatedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    return postAuthenticatedJson(path, body);
  }

  Future<String?> readAccessToken() => _tokenStorage.readAccessToken();

  /// Refreshes the current session, sharing an in-flight refresh request with
  /// other callers so simultaneous 401 responses do not rotate the token more
  /// than once.
  Future<LoginResponse> refreshToken() => _refreshOnce();

  Future<AuthenticatedUser?> restoreSession() async {
    var token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      var response = await _getCurrentUser(token);

      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshToken = await _tokenStorage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _tokenStorage.clear();
          return null;
        }

        // Access tokens can expire while the application is closed. Restore
        // the long-lived session with the saved refresh token before deciding
        // that the user must sign in again.
        final refreshed = await _refreshOnce();
        token = refreshed.accessToken;
        response = await _getCurrentUser(token);

        if (response.statusCode == 401 || response.statusCode == 403) {
          await _tokenStorage.clear();
          return null;
        }
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

  Future<http.Response> _getCurrentUser(String accessToken) {
    return _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        )
        .timeout(const Duration(seconds: 15));
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
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final payload = await _postJson(path, body, timeout: timeout);

    if (payload['otpRequired'] == true) {
      final email = payload['email'];
      if (payload['purpose'] == 'registration') {
        throw RegistrationOtpRequiredException(email is String ? email : '');
      }
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
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      if (path == '/api/v1/auth/login') {
        throw const AuthException(
          'The server took too long to respond (it may be waking up). Please wait a moment and try again.',
        );
      }
      final sendsEmail =
          path == '/api/v1/auth/google' ||
          path == '/api/v1/auth/register' ||
          path == '/api/v1/auth/resend-login-code' ||
          path == '/api/v1/auth/resend-registration-code' ||
          path == '/api/v1/auth/forgot-password';
      throw AuthException(
        sendsEmail
            ? 'The server took too long while sending the verification email. '
                'The code may still arrive; wait a moment, then try again.'
            : 'The server took too long to respond (it may be waking up). Check that the API is '
                'running and try again.',
      );
    } on http.ClientException {
      throw const AuthException(
        'Unable to connect to the server. Please check your internet connection and try again.',
      );
    } catch (e) {
      if (e is TimeoutException || e is AuthException) rethrow;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') ||
          errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('handshake') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('refused')) {
        throw const AuthException(
          'Unable to connect to the server. Please check your internet connection and try again.',
        );
      }
      throw AuthException('An unexpected error occurred: $e');
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
        _errorMessage(response, payload, path: path),
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return const <String, dynamic>{};
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

  String _errorMessage(
    http.Response response,
    Map<String, dynamic>? payload, {
    String? path,
  }) {
    final apiMessage = payload?['message'] ?? payload?['error'];
    if (apiMessage is String && apiMessage.trim().isNotEmpty) {
      return apiMessage.trim();
    }

    final isAuthEndpoint =
        path != null &&
        (path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/verify'));
    final isPasswordRecovery =
        path != null &&
        (path.contains('/auth/forgot-password') ||
            path.contains('/auth/verify-reset-code') ||
            path.contains('/auth/reset-password'));

    return switch (response.statusCode) {
      301 || 302 || 303 || 307 || 308 =>
        'The API redirected the sign-in request to a web page. Restart the API '
            'and verify API_BASE_URL (${ApiConfig.baseUrl}).',
      400 =>
        isPasswordRecovery
            ? 'The password recovery request was rejected by the server.'
            : isAuthEndpoint
            ? 'The sign-in request was rejected by the server.'
            : 'The request was rejected by the server.',
      401 =>
        isAuthEndpoint
            ? 'Invalid email or password.'
            : 'Your session has expired. Please sign in again.',
      403 => 'This account is not allowed to perform this action.',
      404 =>
        isAuthEndpoint
            ? 'The sign-in endpoint was not found. Verify API_BASE_URL (${ApiConfig.baseUrl}).'
            : 'The requested resource was not found.',
      500 =>
        isPasswordRecovery
            ? 'The server could not complete password recovery. Check the API logs.'
            : isAuthEndpoint
            ? 'The server could not complete sign in. Check the API logs.'
            : 'The server encountered an error. Check the API logs.',
      502 ||
      503 ||
      504 => 'The service is temporarily unavailable. Try again shortly.',
      _ => 'Request failed (HTTP ${response.statusCode}).',
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

/// The credentials were submitted, but the server was still completing the
/// login-code delivery when the client timeout elapsed. The verification
/// screen remains safe to open because no session is issued without the code.
class LoginOtpDeliveryPendingException extends AuthException {
  const LoginOtpDeliveryPendingException(this.email)
    : super(
        'The verification email is taking longer than expected. Enter the code when it arrives, or request a new one.',
      );

  final String email;
}

class RegistrationOtpRequiredException extends AuthException {
  const RegistrationOtpRequiredException(this.email)
    : super('A verification code was sent to your email.');

  final String email;
}
