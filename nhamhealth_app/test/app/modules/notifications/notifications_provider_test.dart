import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/app/modules/providers/notifications/notifications_provider.dart';
import 'package:nhamhealth_flutter/config/api_config.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  test('loads the real actor profile image from the configured API host', () async {
    final provider = NotificationsProvider(
      authService: _AuthenticatedAuthService(),
      client: MockClient(
        (request) async => http.Response(
          jsonEncode([
            {
              'id': 5,
              'type': 'COMMUNITY',
              'title': 'Maya Chen',
              'message': 'commented on your post.',
              'actorUserId': 7,
              'actorAvatarUrl': '/uploads/profile-images/maya.jpg',
              'read': false,
              'createdAt': DateTime.now().toIso8601String(),
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    final notifications = await provider.getNotifications();

    expect(notifications.single.actorUserId, 7);
    expect(
      notifications.single.actorAvatarUrl,
      '${ApiConfig.baseUrl}/uploads/profile-images/maya.jpg',
    );
  });
}

class _AuthenticatedAuthService extends AuthService {
  @override
  Future<String?> readAccessToken() async => 'test-token';
}
