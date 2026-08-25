import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/inner_shadow.dart';
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
                const _NotificationsHeader(),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.notifications.isEmpty) {
                      return const SingleChildScrollView(
                        physics: NeverScrollableScrollPhysics(),
                        padding: AppSpacing.pagePadding,
                        child: PageSkeleton.notifications(),
                      );
                    }
                    if (controller.notifications.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () => controller.load(),
                        child: ListView(
                          key: const ValueKey<String>('notifications-list'),
                          padding: AppSpacing.pagePadding,
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
                        padding: AppSpacing.pagePadding,
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
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey<String>('notifications-back-button'),
              tooltip: 'Back'.tr,
              onPressed: Get.back,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.darkGreen,
                size: 25,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              'notifications'.tr,
              style: const TextStyle(
                color: Color(0xFF171717),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
        Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 8),
          child: Text(
            title.tr,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...notifications.map(
          (notification) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _NotificationTile(
              notification: notification,
              onTap: () => onTap(notification),
            ),
          ),
        ),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.notificationTile,
        ),
        child: InnerShadow(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
            child: Row(
              children: [
                _NotificationLeading(notification: notification),
                const SizedBox(width: 11),
                Expanded(child: _NotificationCopy(notification: notification)),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        notification.isUnread
                            ? AppColors.primaryGreen
                            : const Color(0xFF929292),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color:
                notification.kind == NotificationKind.wellness
                    ? const Color(0xFFE5F1FF)
                    : const Color(0xFFE8FFF0),
            shape: BoxShape.circle,
            border:
                isSocial
                    ? Border.all(color: const Color(0xFFFFB4C1), width: 1.5)
                    : null,
          ),
          clipBehavior: Clip.antiAlias,
          child:
              isSocial
                  ? _SocialNotificationAvatar(
                    imageUrl: notification.actorAvatarUrl,
                  )
                  : Icon(
                    notification.icon,
                    size: 25,
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
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF2E8BFF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                size: 7,
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
      size: 25,
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

class _NotificationCopy extends StatelessWidget {
  const _NotificationCopy({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final titleColor = switch (notification.kind) {
      NotificationKind.social => AppColors.primaryGreen,
      NotificationKind.recommendation => const Color(0xFFFF3838),
      NotificationKind.wellness => const Color(0xFFFF3838),
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: notification.title.tr,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' ${notification.message.tr}',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 1.08),
        ),
        const SizedBox(height: 2),
        Text(
          notification.time.tr,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 8,
            height: 1,
          ),
        ),
      ],
    );
  }
}
