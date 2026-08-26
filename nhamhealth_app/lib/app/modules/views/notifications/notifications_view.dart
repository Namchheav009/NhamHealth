import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/notifications/notifications_controller.dart';
import '../../models/notifications/notification_item.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<NotificationsController>()
            ? Get.find<NotificationsController>()
            : Get.put(NotificationsController());
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: AppColors.homeBackground,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                _NotificationsHeader(controller: controller),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.notifications.isEmpty) {
                      return const SingleChildScrollView(
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: PageSkeleton.notifications(),
                      );
                    }
                    if (controller.notifications.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () => controller.load(),
                        child: ListView(
                          key: const ValueKey<String>('notifications-list'),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: [
                            _NotificationSection(
                              title: 'New',
                              notifications: const [],
                              onTap: (_) {},
                            ),
                            const SizedBox(height: 13),
                            _NotificationSection(
                              title: 'Today',
                              notifications: const [],
                              onTap: (_) {},
                            ),
                            const SizedBox(height: 13),
                            _NotificationSection(
                              title: 'Earlier',
                              notifications: const [],
                              onTap: (_) {},
                            ),
                            const SizedBox(height: 100),
                            Center(child: Text('No notifications yet'.tr)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => controller.load(),
                      child: ListView(
                        key: const ValueKey<String>('notifications-list'),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          _NotificationSection(
                            title: 'New',
                            notifications: controller.unread,
                            onTap: controller.open,
                          ),
                          const SizedBox(height: 13),
                          _NotificationSection(
                            title: 'Today',
                            notifications: controller.today,
                            onTap: controller.open,
                          ),
                          const SizedBox(height: 13),
                          _NotificationSection(
                            title: 'Earlier',
                            notifications: controller.earlier,
                            onTap: controller.open,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({required this.controller});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.topBarPagePadding,
      child: AppBackHeader(
        title: 'notifications',
        backButtonKey: const ValueKey<String>('notifications-back-button'),
        onBack: Get.back,
        trailing: Obx(
          () => controller.unread.isEmpty
              ? const SizedBox(width: 44)
              : IconButton(
                  tooltip: 'Mark all as read',
                  onPressed: controller.markAllRead,
                  icon: const Icon(Icons.done_all_rounded),
                  color: AppColors.primaryGreen,
                ),
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.title,
    required this.notifications,
    required this.onTap,
  });

  final String title;
  final List<NotificationItem> notifications;
  final ValueChanged<NotificationItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notifications.isEmpty)
          const SizedBox.shrink()
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 7, 4, 8),
            child: Text(
              title.tr,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...notifications.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: _NotificationTile(
                notification: notification,
                onTap: () => onTap(notification),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        constraints: const BoxConstraints(minHeight: 82),
        decoration: BoxDecoration(
          color: notification.isUnread
              ? const Color(0xFFEAF7F0)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                _NotificationLeading(notification: notification),
                const SizedBox(width: 11),
                Expanded(child: _NotificationCopy(notification: notification)),
                const SizedBox(width: 4),
                SizedBox(
                  width: 28,
                  child: notification.isUnread
                      ? const Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(width: 11, height: 11),
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9AA29E),
                          size: 22,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final isSocial = notification.kind == NotificationKind.social;
    final isNhamHealth = notification.kind == NotificationKind.system;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color:
                notification.kind == NotificationKind.wellness
                    ? const Color(0xFFE5F1FF)
                    : const Color(0xFFE8FFF0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child:
              isSocial
                  ? _SocialNotificationAvatar(
                    imageUrl: notification.actorAvatarUrl,
                  )
                  : isNhamHealth
                  ? const _NhamHealthNotificationAvatar()
                  : Icon(
                    notification.icon,
                    size: 29,
                    color:
                        notification.kind == NotificationKind.wellness
                            ? const Color(0xFF4396FF)
                            : AppColors.primaryGreen,
                  ),
        ),
        if (notification.hasMessageBadge)
          Positioned(
            right: -2,
            bottom: -1,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF2E8BFF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _SocialNotificationAvatar extends StatelessWidget {
  const _SocialNotificationAvatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.person_rounded,
      size: 30,
      color: AppColors.primaryGreen,
    );
    if (imageUrl.isEmpty) return fallback;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _NhamHealthNotificationAvatar extends StatelessWidget {
  const _NhamHealthNotificationAvatar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Image.asset(
        'assets/icons/logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'Nham Health',
      ),
    );
  }
}

class _NotificationCopy extends StatelessWidget {
  const _NotificationCopy({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: notification.displayTitle.tr,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' ${notification.displayMessage.tr}',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, height: 1.25),
        ),
        const SizedBox(height: 5),
        Text(
          notification.time.tr,
          style: TextStyle(
            color: notification.isUnread
                ? AppColors.primaryGreen
                : AppColors.secondaryText,
            fontSize: 12,
            fontWeight: notification.isUnread
                ? FontWeight.w700
                : FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}
