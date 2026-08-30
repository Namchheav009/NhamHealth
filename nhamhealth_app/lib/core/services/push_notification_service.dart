import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../app/routes/app_routes.dart';
import '../../app/widgets/app_alert.dart';
import '../../config/api_config.dart';
import 'auth_service.dart';
import 'notification_realtime_event.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService({
    required AuthService authService,
    http.Client? client,
  }) : _authService = authService,
       _client = client ?? http.Client();

  static PushNotificationService? instance;
  static const _androidNotifications = MethodChannel(
    'com.example.nhamhealth_flutter/notifications',
  );

  final AuthService _authService;
  final http.Client _client;
  final StreamController<NotificationRealtimeEvent> _events =
      StreamController<NotificationRealtimeEvent>.broadcast(sync: true);
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;
  String? _token;

  Stream<NotificationRealtimeEvent> get events => _events.stream;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> initialize() async {
    if (!isSupported) return;
    instance = this;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    _tokenSubscription = messaging.onTokenRefresh.listen(_registerToken);
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) async {
      _publish(message);
      final notification = message.notification;
      if (notification == null) return;
      final title = notification.title ?? 'NhamHealth';
      final body = notification.body ?? '';
      try {
        await _androidNotifications.invokeMethod<void>('showNotification', {
          'title': title,
          'body': body,
        });
      } on Object {
        AppAlert.success(title: title, message: body);
      }
    });
    _tapSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_open);
    _token = await messaging.getToken();
    await syncToken();

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _open(initialMessage),
      );
    }
  }

  void _publish(RemoteMessage message) {
    if (_events.isClosed) return;
    final notification = message.notification;
    _events.add(
      NotificationRealtimeEvent(
        id: int.tryParse(message.data['notificationId'] ?? ''),
        title: notification?.title ?? 'NhamHealth',
        message: notification?.body ?? '',
        referenceType: message.data['referenceType']?.trim().toUpperCase(),
        referenceId: int.tryParse(message.data['referenceId'] ?? ''),
      ),
    );
  }

  Future<void> syncToken() async {
    if (!isSupported) return;
    final token = _token ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    _token = token;
    await _registerToken(token);
  }

  Future<void> unregister() async {
    final token = _token;
    final accessToken = await _authService.readAccessToken();
    if (token == null || accessToken == null) return;
    await _sendDeviceRequest('DELETE', token, accessToken);
  }

  Future<void> _registerToken(String token) async {
    _token = token;
    final accessToken = await _authService.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;
    try {
      await _sendDeviceRequest('PUT', token, accessToken);
    } on Object {
      // Registration retries at the next login, app start, or token refresh.
    }
  }

  Future<void> _sendDeviceRequest(
    String method,
    String token,
    String accessToken,
  ) async {
    final request =
        http.Request(
            method,
            Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/devices'),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          })
          ..body = jsonEncode({
            'token': token,
            'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
          });
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Device registration failed (${response.statusCode})',
      );
    }
  }

  void _open(RemoteMessage message) {
    final referenceType = message.data['referenceType']?.toUpperCase();
    final referenceId = int.tryParse(message.data['referenceId'] ?? '');
    if (referenceType == 'POST' && referenceId != null) {
      Get.toNamed<void>(AppRoutes.communityPostPath(referenceId));
      return;
    }
    Get.toNamed<void>(AppRoutes.notifications);
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _tapSubscription?.cancel();
    await _events.close();
    _client.close();
    if (identical(instance, this)) instance = null;
  }
}
