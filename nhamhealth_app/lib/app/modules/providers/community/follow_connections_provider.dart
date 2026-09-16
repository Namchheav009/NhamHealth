import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';

class FollowConnectionsProvider {
  FollowConnectionsProvider({required AuthService authService, Dio? dio})
    : _authService = authService,
      _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  final AuthService _authService;
  final Dio _dio;

  Future<Map<String, dynamic>> create(int receiverId) =>
      _post('/api/follows/connections', data: {'receiverId': receiverId});

  Future<Map<String, dynamic>> accept(int requestId) =>
      _post('/api/follows/connections/$requestId/accept');

  Future<Map<String, dynamic>> decline(int requestId) =>
      _post('/api/follows/connections/$requestId/decline');

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final token = await _authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const FollowConnectionApiException(
        'Please sign in to manage invitations.',
      );
    }
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data is! Map) {
        throw const FollowConnectionApiException(
          'The server returned an invalid follow-connection response.',
        );
      }
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      final response = error.response;
      final body = response?.data;
      final message =
          body is Map && body['message'] is String
              ? (body['message'] as String).trim()
              : 'Invitation failed (${response?.statusCode ?? 'offline'}).';
      throw FollowConnectionApiException(
        message,
        statusCode: response?.statusCode,
        retryAfter: _retryAfter(response),
      );
    }
  }

  Duration? _retryAfter(Response<dynamic>? response) {
    if (response?.statusCode != 429) return null;
    final raw = response?.headers.value('retry-after');
    final seconds = int.tryParse(raw ?? '');
    if (seconds != null) return Duration(seconds: seconds);
    final body = response?.data;
    final bodySeconds =
        body is Map ? (body['retryAfterSeconds'] as num?)?.toInt() : null;
    return bodySeconds == null
        ? const Duration(seconds: 60)
        : Duration(seconds: bodySeconds);
  }
}

class FollowConnectionApiException implements Exception {
  const FollowConnectionApiException(
    this.message, {
    this.statusCode,
    this.retryAfter,
  });

  final String message;
  final int? statusCode;
  final Duration? retryAfter;
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => message;
}
