import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';
import 'package:nhamhealth_flutter/core/services/push_notification_service.dart';

class _Messaging extends Fake implements FirebaseMessaging {
  bool unavailable = true;

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    if (unavailable) {
      throw FirebaseException(
        plugin: 'firebase_messaging',
        code: 'unknown',
        message: 'FCM Registration failed!',
      );
    }
    return 'recovered-token';
  }
}

class _AuthService extends Fake implements AuthService {
  @override
  Future<String?> readAccessToken() async => 'access-token';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FCM failure is nonfatal and registration recovers on retry', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final messaging = _Messaging();
    final requests = <http.Request>[];
    final service = PushNotificationService(
      authService: _AuthService(),
      messaging: messaging,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', 204);
      }),
    );
    addTearDown(service.dispose);

    await expectLater(service.syncToken(), completes);
    expect(requests, isEmpty);

    messaging.unavailable = false;
    await service.syncToken();
    expect(requests, hasLength(1));
    expect(requests.single.method, 'PUT');
    expect(jsonDecode(requests.single.body)['token'], 'recovered-token');
  });
}
