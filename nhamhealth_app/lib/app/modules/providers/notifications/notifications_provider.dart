import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/notifications/notification_item.dart';

class NotificationsProvider {
  NotificationsProvider({required AuthService authService, http.Client? client})
    : _authService = authService,
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<List<NotificationItem>> getNotifications() async {
    final response = await _request('GET');
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<void> markRead(int id) async => _request('PATCH', id: id);

  Future<http.Response> _request(String method, {int? id}) async {
    final token = await _authService.readAccessToken();
    if (token == null || token.isEmpty) throw const NotificationsException('Your session has expired.');
    final suffix = id == null ? '' : '/$id/read';
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications$suffix');
    final headers = {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
    final response = method == 'PATCH'
        ? await _client.patch(uri, headers: headers)
        : await _client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationsException('Unable to load notifications (HTTP ${response.statusCode}).');
    }
    return response;
  }
}

class NotificationsException implements Exception {
  const NotificationsException(this.message);
  final String message;
  @override String toString() => message;
}
