import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/assistant/assistant_message.dart';

class AssistantProvider {
  AssistantProvider({required AuthService authService, http.Client? client})
    : _authService = authService,
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<String> sendMessage({
    required String message,
    required List<AssistantMessage> history,
  }) async {
    final token = await _authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AssistantException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/ai-assistant/chat'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'message': message,
              'date': _dateOnly(DateTime.now()),
              'history': history.map((item) => item.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 70));

      Map<String, dynamic>? payload;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) payload = decoded;
      } on Object {
        payload = null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final serverMessage = payload?['detail'] ?? payload?['message'];
        throw AssistantException(
          serverMessage is String && serverMessage.trim().isNotEmpty
              ? serverMessage.trim()
              : 'The AI assistant is unavailable (HTTP ${response.statusCode}).',
        );
      }
      final reply = payload?['reply'];
      if (reply is! String || reply.trim().isEmpty) {
        throw const AssistantException(
          'The AI assistant returned an incomplete response.',
        );
      }
      return reply.trim();
    } on AssistantException {
      rethrow;
    } on TimeoutException {
      throw const AssistantException(
        'The AI assistant took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AssistantException(
        'Could not connect to the NhamHealth server.',
      );
    } on Object {
      throw const AssistantException(
        'The AI assistant could not process this reply. Please try again.',
      );
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class AssistantException implements Exception {
  const AssistantException(this.message);

  final String message;

  @override
  String toString() => message;
}
