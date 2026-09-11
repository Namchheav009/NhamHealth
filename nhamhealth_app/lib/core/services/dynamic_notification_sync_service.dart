import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/modules/models/notifications/notification_item.dart';
import '../../app/modules/providers/notifications/notifications_provider.dart';
import '../../app/modules/repositories/notifications/notifications_repository.dart';
import 'auth_service.dart';
import 'push_notification_service.dart';

class DynamicNotificationSyncService extends GetxService with WidgetsBindingObserver {
  DynamicNotificationSyncService({
    required AuthService authService,
    NotificationsRepository? repository,
  })  : _authService = authService,
        _repository = repository ??
            NotificationsRepository(
              provider: NotificationsProvider(authService: authService),
            );

  static DynamicNotificationSyncService? get instance =>
      Get.isRegistered<DynamicNotificationSyncService>()
          ? Get.find<DynamicNotificationSyncService>()
          : null;

  final AuthService _authService;
  final NotificationsRepository _repository;
  final Set<int> _notifiedNotificationIds = <int>{};

  Timer? _pollTimer;
  bool _initialLoadDone = false;
  bool _syncInFlight = false;

  static const Duration defaultPollInterval = Duration(seconds: 12);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    startSync();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    stopSync();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncNow());
    }
  }

  void startSync({Duration interval = defaultPollInterval}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => unawaited(syncNow()));
    unawaited(syncNow());
  }

  void stopSync() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> syncNow() async {
    if (_syncInFlight) return;
    _syncInFlight = true;

    try {
      final token = await _authService.readAccessToken();
      if (token == null || token.isEmpty) {
        _initialLoadDone = false;
        _notifiedNotificationIds.clear();
        return;
      }

      final items = await _repository.getNotifications();
      if (!_initialLoadDone) {
        _notifiedNotificationIds.addAll(items.map((item) => item.id));
        _initialLoadDone = true;
        return;
      }

      final newUnread = items
          .where((item) => item.isUnread && !_notifiedNotificationIds.contains(item.id))
          .toList();

      for (final item in newUnread) {
        _notifiedNotificationIds.add(item.id);
        await _dispatchSystemAlert(item);
      }
    } on Object catch (error) {
      debugPrint('Dynamic notification sync unavailable: $error');
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _dispatchSystemAlert(NotificationItem item) async {
    final pushService = PushNotificationService.instance;
    if (pushService == null) return;

    final avatarUrl = item.actorAvatarUrl.isNotEmpty ? item.actorAvatarUrl : null;
    await pushService.showDynamicNotification(
      title: item.displayTitle,
      body: item.displayMessage,
      subText: item.actionLabel.tr,
      avatarUrl: avatarUrl,
      referenceType: item.referenceType,
      referenceId: item.referenceId?.toString(),
      notificationId: item.id.toString(),
    );
  }

}
