import 'dart:async';

import 'package:get/get.dart';

import '../../../widgets/app_alert.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/services/notification_realtime_event.dart';
import '../../../../core/services/dynamic_notification_sync_service.dart';
import '../../models/notifications/notification_item.dart';
import '../../repositories/notifications/notifications_repository.dart';

class NotificationsController extends GetxController {
  NotificationsController({this.repository, this.realtimeEvents});
  final NotificationsRepository? repository;
  final Stream<NotificationRealtimeEvent>? realtimeEvents;
  final notifications = <NotificationItem>[].obs;
  final isLoading = false.obs;
  final isMarkingAllRead = false.obs;
  Timer? _refreshTimer;
  StreamSubscription<NotificationRealtimeEvent>? _realtimeSubscription;
  bool _requestInFlight = false;
  bool _hasLoaded = false;
  bool _reloadRequested = false;
  final Set<int> _knownNotificationIds = <int>{};

  static const refreshInterval = Duration(seconds: 5);

  List<NotificationItem> get unread =>
      notifications.where((item) => item.isUnread).toList();
  List<NotificationItem> get today =>
      notifications
          .where((item) => !item.isUnread && _isToday(item.createdAt))
          .toList();
  List<NotificationItem> get earlier =>
      notifications
          .where((item) => !item.isUnread && !_isToday(item.createdAt))
          .toList();

  @override
  void onInit() {
    super.onInit();
    load();
    _realtimeSubscription = realtimeEvents?.listen(
      (_) => load(silent: true, announceNew: false),
    );
    if (repository != null) {
      _refreshTimer = Timer.periodic(
        refreshInterval,
        (_) => load(silent: true),
      );
    }
  }

  Future<void> load({bool silent = false, bool announceNew = true}) async {
    final repository = this.repository;
    if (repository == null) return;
    if (_requestInFlight) {
      _reloadRequested = true;
      return;
    }
    _requestInFlight = true;
    try {
      if (!silent) isLoading.value = true;
      final result = await repository.getNotifications();
      final newItems =
          _hasLoaded
              ? result
                  .where(
                    (item) =>
                        item.isUnread &&
                        !_knownNotificationIds.contains(item.id),
                  )
                  .toList()
              : const <NotificationItem>[];
      _knownNotificationIds.addAll(result.map((item) => item.id));
      notifications.assignAll(result);
      DynamicNotificationSyncService.instance?.updateUnreadCount(
        result.where((item) => item.isUnread).length,
      );
      _hasLoaded = true;
      if (silent && announceNew && newItems.isNotEmpty) {
        final newest = newItems.first;
        AppAlert.notification(
          title: newest.displayTitle,
          message: newest.displayMessage,
        );
      }
    } on Object catch (error) {
      if (!silent) {
        AppAlert.error(
          title: 'notifications.notifications_unavailable',
          message: error.toString(),
        );
      }
    } finally {
      _requestInFlight = false;
      if (!silent) isLoading.value = false;
      if (_reloadRequested) {
        _reloadRequested = false;
        unawaited(load(silent: true, announceNew: false));
      }
    }
  }

  Future<void> markRead(NotificationItem item) async {
    final repository = this.repository;
    if (repository == null) return;
    if (!item.isUnread) return;
    final index = notifications.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    notifications[index] = item.copyWith(isUnread: false);
    DynamicNotificationSyncService.instance?.updateUnreadCount(unread.length);
    try {
      await repository.markRead(item.id);
    } on Object catch (error) {
      notifications[index] = item;
      DynamicNotificationSyncService.instance?.updateUnreadCount(unread.length);
      AppAlert.error(
        title: 'notifications.notification_not_updated',
        message: error.toString(),
      );
    }
  }

  Future<bool> markAllRead() async {
    final repository = this.repository;
    final unreadItems = unread;
    if (repository == null || unreadItems.isEmpty || isMarkingAllRead.value) {
      return false;
    }

    final previous = List<NotificationItem>.from(notifications);
    isMarkingAllRead.value = true;
    notifications.assignAll(
      notifications.map((item) => item.copyWith(isUnread: false)),
    );
    DynamicNotificationSyncService.instance?.updateUnreadCount(0);
    try {
      for (final item in unreadItems) {
        await repository.markRead(item.id);
      }
      return true;
    } on Object catch (error) {
      notifications.assignAll(previous);
      DynamicNotificationSyncService.instance?.updateUnreadCount(unread.length);
      AppAlert.error(
        title: 'notifications.not_updated',
        message: error.toString(),
      );
      return false;
    } finally {
      isMarkingAllRead.value = false;
    }
  }

  Future<void> open(NotificationItem item) async {
    await markRead(item);
    if (item.referenceType == 'POST' && item.referenceId != null) {
      await Get.toNamed<void>(
        AppRoutes.communityPostPath(item.referenceId!),
        arguments: {'source': 'notification', 'action': item.action.name},
      );
      return;
    }
    if (item.referenceType == 'USER' && item.referenceId != null) {
      await Get.toNamed<void>(
        AppRoutes.communityPersonProfilePath(item.referenceId!),
      );
      return;
    }
    if (item.referenceType == 'AI_FOOD') {
      await Get.toNamed<void>(AppRoutes.aiFood);
      return;
    }
    if (item.referenceType == 'SECURITY') {
      await Get.toNamed<void>(AppRoutes.settings);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _realtimeSubscription?.cancel();
    super.onClose();
  }
}
