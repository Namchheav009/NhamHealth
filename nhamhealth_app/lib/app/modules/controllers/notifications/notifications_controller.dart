import 'dart:async';

import 'package:get/get.dart';

import '../../../widgets/app_alert.dart';
import '../../../routes/app_routes.dart';
import '../../models/notifications/notification_item.dart';
import '../../repositories/notifications/notifications_repository.dart';

class NotificationsController extends GetxController {
  NotificationsController({this.repository});
  final NotificationsRepository? repository;
  final notifications = <NotificationItem>[].obs;
  final isLoading = false.obs;
  Timer? _refreshTimer;
  bool _requestInFlight = false;
  bool _hasLoaded = false;

  static const refreshInterval = Duration(seconds: 5);

  List<NotificationItem> get unread => notifications.where((item) => item.isUnread).toList();
  List<NotificationItem> get today => notifications.where((item) => !item.isUnread && _isToday(item.createdAt)).toList();
  List<NotificationItem> get earlier => notifications.where((item) => !item.isUnread && !_isToday(item.createdAt)).toList();

  @override
  void onInit() {
    super.onInit();
    load();
    if (repository != null) {
      _refreshTimer = Timer.periodic(
        refreshInterval,
        (_) => load(silent: true),
      );
    }
  }

  Future<void> load({bool silent = false}) async {
    final repository = this.repository;
    if (repository == null || _requestInFlight) return;
    _requestInFlight = true;
    try {
      if (!silent) isLoading.value = true;
      final result = await repository.getNotifications();
      final existingIds = notifications.map((item) => item.id).toSet();
      final newItems = _hasLoaded
          ? result.where((item) => !existingIds.contains(item.id)).toList()
          : const <NotificationItem>[];
      notifications.assignAll(result);
      _hasLoaded = true;
      if (silent && newItems.isNotEmpty) {
        final newest = newItems.first;
        AppAlert.success(
          title: newest.title,
          message: newest.message,
        );
      }
    } on Object catch (error) {
      if (!silent) {
        AppAlert.error(
          title: 'Notifications unavailable',
          message: error.toString(),
        );
      }
    } finally {
      _requestInFlight = false;
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> markRead(NotificationItem item) async {
    final repository = this.repository;
    if (repository == null) return;
    if (!item.isUnread) return;
    final index = notifications.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    notifications[index] = item.copyWith(isUnread: false);
    try {
      await repository.markRead(item.id);
    } on Object catch (error) {
      notifications[index] = item;
      AppAlert.error(title: 'Notification not updated', message: error.toString());
    }
  }

  Future<void> markAllRead() async {
    final repository = this.repository;
    final unreadItems = unread;
    if (repository == null || unreadItems.isEmpty) return;

    final previous = List<NotificationItem>.from(notifications);
    notifications.assignAll(
      notifications.map((item) => item.copyWith(isUnread: false)),
    );
    try {
      for (final item in unreadItems) {
        await repository.markRead(item.id);
      }
    } on Object catch (error) {
      notifications.assignAll(previous);
      AppAlert.error(
        title: 'Notifications not updated',
        message: error.toString(),
      );
    }
  }

  Future<void> open(NotificationItem item) async {
    await markRead(item);
    if (item.referenceType == 'POST' && item.referenceId != null) {
      await Get.toNamed<void>(
        AppRoutes.communityPostPath(item.referenceId!),
      );
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
