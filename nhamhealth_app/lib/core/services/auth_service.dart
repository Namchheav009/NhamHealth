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
      response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AuthException(
        'Could not connect to the server. Check that the API is running.',
      );
    }

    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      throw const AuthException('The server returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload['message'] as String? ??
            payload['error'] as String? ??
            'Authentication failed. Please try again.',
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
}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
