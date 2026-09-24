import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
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
    final isTablet = AppSpacing.isTabletFor(context);
    final horizontalPadding = AppSpacing.pageHorizontalFor(context);
    final contentMaxWidth =
        isTablet
            ? AppSpacing.maxWideContentWidth
            : AppSpacing.maxContentWidth;
    final paddedMaxWidth = contentMaxWidth + (horizontalPadding * 2);
    final listPadding = EdgeInsets.fromLTRB(
      horizontalPadding,
      8,
      horizontalPadding,
      32,
    );
    final skeletonPadding = EdgeInsets.fromLTRB(
      horizontalPadding,
      12,
      horizontalPadding,
      24,
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: paddedMaxWidth),
                    child: const _NotificationsHeader(),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.notifications.isEmpty) {
                      return Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: paddedMaxWidth),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: skeletonPadding,
                            child: const PageSkeleton.notifications(),
                          ),
                        ),
                      );
                    }
                    if (controller.notifications.isEmpty) {
                      return Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: paddedMaxWidth),
                          child: RefreshIndicator(
                            onRefresh: () => controller.load(),
                            child: ListView(
                              key: const ValueKey<String>(
                                'notifications-list',
                              ),
                              padding: listPadding,
                              children: [
                                _NotificationSection(
                                  title: 'notifications.new',
                                  notifications: const [],
                                  alwaysShowTitle: true,
                                  onTap: (_) {},
                                ),
                                const SizedBox(height: 13),
                                _NotificationSection(
                                  title: 'common.today',
                                  notifications: const [],
                                  alwaysShowTitle: true,
                                  onTap: (_) {},
                                ),
                                const SizedBox(height: 13),
                                _NotificationSection(
                                  title: 'notifications.earlier',
                                  notifications: const [],
                                  alwaysShowTitle: true,
                                  onTap: (_) {},
                                ),
                                const SizedBox(height: 100),
                                Center(
                                  child: Text(
                                    'notifications.no_notifications_yet'.tr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: paddedMaxWidth),
                        child: RefreshIndicator(
                          onRefresh: () => controller.load(),
                          child: ListView(
                            key: const ValueKey<String>(
                              'notifications-list',
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: listPadding,
                            children: [
                              _NotificationSection(
                                title: 'notifications.new',
                                notifications: controller.unread,
                                onTap: controller.open,
                              ),
                              const SizedBox(height: 13),
                              _NotificationSection(
                                title: 'common.today',
                                notifications: controller.today,
                                onTap: controller.open,
                              ),
                              const SizedBox(height: 13),
                              _NotificationSection(
                                title: 'notifications.earlier',
                                notifications: controller.earlier,
                                onTap: controller.open,
                              ),
                            ],
                          ),
                        ),
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
    final horizontalPadding = AppSpacing.pageHorizontalFor(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.pageTop,
        horizontalPadding,
        0,
      ),
      child: AppBackHeader(
        title: 'common.notifications',
        backButtonKey: const ValueKey<String>('notifications-back-button'),
        onBack: Get.back,
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.title,
    required this.notifications,
    required this.onTap,
    this.alwaysShowTitle = false,
  });

  final String title;
  final List<NotificationItem> notifications;
  final ValueChanged<NotificationItem> onTap;
  final bool alwaysShowTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notifications.isEmpty && !alwaysShowTitle)
          const SizedBox.shrink()
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 7, 4, 8),
            child: Text(
              title.trOrSelf,
              style: TextStyle(
                color: context.appText,
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
          color:
              notification.isUnread ? context.appSoftGreen : Colors.transparent,
          border: Border.all(
            color:
                notification.isUnread
                    ? context.appColorScheme.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
          ),
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
                child:
                    notification.isUnread
                        ? const Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(width: 11, height: 11),
                          ),
                        )
                        : Icon(
                          Icons.chevron_right_rounded,
                          color: context.appMutedText,
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
    final accent = notification.actionColor;
    final iconBackground = Color.alphaBlend(
      accent.withValues(alpha: 0.12),
      context.appSurface,
    );
    final iconHighlight = Color.alphaBlend(
      accent.withValues(alpha: 0.04),
      context.appSurface,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient:
                isSocial
                    ? null
                    : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [iconHighlight, iconBackground],
                    ),
            color: isSocial ? iconBackground : null,
            shape: isSocial ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isSocial ? null : BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child:
              isSocial
                  ? _SocialNotificationAvatar(
                    imageUrl: notification.actorAvatarUrl,
                    displayName: notification.displayTitle,
                    accent: accent,
                  )
                  : isNhamHealth
                  ? const _NhamHealthNotificationAvatar()
                  : Icon(
                    notification.icon,
                    size: 28,
                    color: accent,
                  ),
        ),
        Positioned(
          right: -2,
          bottom: -1,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: notification.actionColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.appSurface, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: notification.actionColor.withValues(alpha: 0.22),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(
              notification.actionIcon,
              size: 12.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialNotificationAvatar extends StatelessWidget {
  const _SocialNotificationAvatar({
    required this.imageUrl,
    required this.displayName,
    required this.accent,
  });

  final String imageUrl;
  final String displayName;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final trimmedName = displayName.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.characters.first;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.72),
            accent,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
      padding: const EdgeInsets.all(7),
      child: Image.asset(
        'assets/icons/primary_logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'Nham Health',
        errorBuilder:
            (_, _, _) => const Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.primaryGreen,
              size: 30,
            ),
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
                text: notification.displayTitle,
                style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' ${notification.displayMessage}',
                style: TextStyle(
                  color: context.appText,
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
        Row(
          children: [
            Text(
              notification.timeTranslationKey.trParams(
                notification.timeTranslationParams,
              ),
              style: TextStyle(
                color:
                    notification.isUnread
                        ? AppColors.primaryGreen
                        : context.appMutedText,
                fontSize: 12,
                fontWeight:
                    notification.isUnread ? FontWeight.w700 : FontWeight.w500,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: context.appMutedText,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                notification.actionLabel.trOrSelf,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: notification.actionColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
