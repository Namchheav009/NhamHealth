import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/modules/auth/models/google_login_request.dart';
import '../../app/modules/auth/models/authenticated_user_model.dart';
import '../../app/modules/auth/models/login_request.dart';
import '../../app/modules/auth/models/login_response.dart';
import '../../app/modules/auth/models/register_request.dart';
import '../../config/api_config.dart';
import '../storage/token_storage.dart';

class AuthService {
  AuthService({http.Client? client, TokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage _tokenStorage;

  Future<LoginResponse> login(LoginRequest request) =>
      _authenticate('/api/v1/auth/login', request.toJson());

  Future<LoginResponse> register(RegisterRequest request) =>
      _authenticate('/api/v1/auth/register', request.toJson());

  Future<LoginResponse> loginWithGoogle(GoogleLoginRequest request) =>
      _authenticate('/api/v1/auth/google', request.toJson());

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

  Future<void> logout() => _tokenStorage.clear();

  Future<LoginResponse> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    final http.Response response;
    try {
      final request =
          http.Request('POST', Uri.parse('${ApiConfig.baseUrl}$path'))
            ..followRedirects = false
            ..headers.addAll(const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            })
            ..body = jsonEncode(body);
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      response = await http.Response.fromStream(streamedResponse);
    } on TimeoutException {
      throw const AuthException(
        'The server took too long to respond. Please try again.',
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

    return result;
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
