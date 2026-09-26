import 'dart:async';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'auth_service.dart';

/// An HTTP client wrapper that transparently handles:
/// 1. Attaching `Authorization: Bearer <token>` when missing for API requests.
/// 2. Catching HTTP 401 Unauthorized responses and attempting to refresh the JWT.
/// 3. Retrying the original request automatically if the token was refreshed successfully.
class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient({
    required AuthService authService,
    http.Client? innerClient,
  })  : _authService = authService,
        _innerClient = innerClient ?? http.Client();

  final AuthService _authService;
  final http.Client _innerClient;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isApiRequest = request.url.toString().startsWith(ApiConfig.baseUrl);
    final isAuthEndpoint = request.url.path.contains('/api/v1/auth/');

    // Do not intercept auth endpoints to prevent infinite refresh loops.
    if (!isApiRequest || isAuthEndpoint) {
      return _innerClient.send(request);
    }

    // Attach Authorization header if missing and a token exists.
    if (!request.headers.containsKey('Authorization')) {
      final token = await _authService.readAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Keep a copy in case we need to retry after 401.
    final requestCopy = _copyRequest(request);
    final response = await _innerClient.send(request);

    if (response.statusCode != 401) {
      return response;
    }

    // 401 encountered - attempt to refresh token
    try {
      final refreshed = await _authService.refreshToken();
      if (refreshed.accessToken.isEmpty) {
        return response;
      }

      if (requestCopy != null) {
        final retryRequest = _copyRequest(
          requestCopy,
          newAccessToken: refreshed.accessToken,
        );
        if (retryRequest != null) {
          return await _innerClient.send(retryRequest);
        }
      }
    } on Object {
      // If refresh fails, return original 401 so callers handle expiry.
      return response;
    }

    return response;
  }

  http.BaseRequest? _copyRequest(
    http.BaseRequest original, {
    String? newAccessToken,
  }) {
    if (original is http.Request) {
      final copy = http.Request(original.method, original.url);
      copy.headers.addAll(original.headers);
      if (newAccessToken != null) {
        copy.headers['Authorization'] = 'Bearer $newAccessToken';
      }
      copy.bodyBytes = original.bodyBytes;
      copy.encoding = original.encoding;
      copy.followRedirects = original.followRedirects;
      copy.maxRedirects = original.maxRedirects;
      copy.persistentConnection = original.persistentConnection;
      return copy;
    } else if (original is http.MultipartRequest) {
      final copy = http.MultipartRequest(original.method, original.url);
      copy.headers.addAll(original.headers);
      if (newAccessToken != null) {
        copy.headers['Authorization'] = 'Bearer $newAccessToken';
      }
      copy.fields.addAll(original.fields);
      copy.files.addAll(original.files);
      copy.followRedirects = original.followRedirects;
      copy.maxRedirects = original.maxRedirects;
      copy.persistentConnection = original.persistentConnection;
      return copy;
    }
    return null;
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }
}
