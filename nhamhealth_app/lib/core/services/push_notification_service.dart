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
    FirebaseMessaging? messaging,
  }) : _authService = authService,
       _client = client ?? http.Client(),
       _messaging = messaging;

  static PushNotificationService? instance;
  static const _androidNotifications = MethodChannel(
    'com.example.nhamhealth_flutter/notifications',
  );

  final AuthService _authService;
  final http.Client _client;
  final FirebaseMessaging? _messaging;
  FirebaseMessaging get _firebaseMessaging =>
      _messaging ?? FirebaseMessaging.instance;
  final StreamController<NotificationRealtimeEvent> _events =
      StreamController<NotificationRealtimeEvent>.broadcast(sync: true);
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;
  String? _token;
  bool _initialized = false;

  Stream<NotificationRealtimeEvent> get events => _events.stream;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    _initialized = true;
    instance = this;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = _firebaseMessaging;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) return;

    _androidNotifications.setMethodCallHandler((call) async {
      if (call.method != 'notificationTapped') return;
      _openNativeNotification(call.arguments);
    });
    final initialNativeNotification = await _androidNotifications
        .invokeMethod<Object?>('getInitialNotificationTap');
    if (initialNativeNotification != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openNativeNotification(initialNativeNotification),
      );
    }
    _tokenSubscription = messaging.onTokenRefresh.listen(
      _registerToken,
      onError: (Object error) {
        debugPrint('Push token refresh unavailable: $error');
      },
    );
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) async {
      _publish(message);
      final notification = message.notification;
      final title =
          notification?.title ?? message.data['title'] ?? 'NhamHealth';
      final body = notification?.body ?? message.data['body'] ?? '';
      try {
        await _androidNotifications.invokeMethod<void>('showNotification', {
          'title': title,
          'body': body,
          'notificationId': message.data['notificationId'] ?? '',
          'referenceType': message.data['referenceType'] ?? '',
          'referenceId': message.data['referenceId'] ?? '',
        });
      } on Object {
        AppAlert.success(title: title, message: body);
      }
    });
    _tapSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _publish(message);
      _open(message);
    });
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _publish(initialMessage);
        _open(initialMessage);
      });
    }
    // Token retrieval can require the network. Do not delay notification taps.
    await syncToken();
  }

  void _publish(RemoteMessage message) {
    if (_events.isClosed) return;
    final notification = message.notification;
    _events.add(
      NotificationRealtimeEvent(
        id: int.tryParse(message.data['notificationId'] ?? ''),
        title: notification?.title ?? message.data['title'] ?? 'NhamHealth',
        message: notification?.body ?? message.data['body'] ?? '',
        referenceType: message.data['referenceType']?.trim().toUpperCase(),
        referenceId: int.tryParse(message.data['referenceId'] ?? ''),
      ),
    );
  }

  Future<void> syncToken() async {
    if (!isSupported) return;
    try {
      final token = _token ?? await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) return;
      _token = token;
      await _registerToken(token);
    } on Object catch (error) {
      // Retry on the next login, app start, or token refresh.
      debugPrint('Push token registration unavailable: $error');
    }
  }

  Future<void> unregister() async {
    final token = _token;
    final accessToken = await _authService.readAccessToken();
    if (token == null || accessToken == null) return;
    await _sendDeviceRequest('DELETE', token, accessToken);
  }

  Future<void> _registerToken(String token) async {
    _token = token;
    try {
      final accessToken = await _authService.readAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
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
    _openData(message.data);
  }

  void _openNativeNotification(Object? rawArguments) {
    final arguments = Map<String, dynamic>.from(
      (rawArguments as Map?) ?? const <String, dynamic>{},
    );
    _openData(arguments);
  }

  void _openData(Map<String, dynamic> data) {
    final referenceType = data['referenceType']?.toString().toUpperCase();
    final referenceId = int.tryParse(data['referenceId']?.toString() ?? '');
    if (referenceType == 'POST' && referenceId != null) {
      Get.toNamed<void>(AppRoutes.communityPostPath(referenceId));
      return;
    }
    if (referenceType == 'USER' && referenceId != null) {
      Get.toNamed<void>(AppRoutes.communityPersonProfilePath(referenceId));
      return;
    }
    Get.toNamed<void>(AppRoutes.notifications);
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _tapSubscription?.cancel();
    _androidNotifications.setMethodCallHandler(null);
    await _events.close();
    _client.close();
    if (identical(instance, this)) instance = null;
  }
}
