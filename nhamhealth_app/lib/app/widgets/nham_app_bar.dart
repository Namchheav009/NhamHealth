import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../modules/models/auth/authenticated_user_model.dart';
import '../modules/views/home/widgets/authenticated_user_avatar.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class NhamAppBar extends StatelessWidget {
  const NhamAppBar({
    super.key,
    required this.user,
    required this.unreadNotificationCount,
    required this.onNotifications,
    required this.onProfile,
    this.onFavorites,
  });

  final AuthenticatedUser? user;
  final int unreadNotificationCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback? onFavorites;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/primary_logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NHAM',
                    style: TextStyle(
                      height: 1.05,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryPink,
                    ),
                  ),
                  Text(
                    'HEALTH',
                    style: TextStyle(
                      height: 1.05,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navigationGreen,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FavoritesButton(
                    onTap:
                        onFavorites ??
                        () => Get.toNamed<void>(AppRoutes.favorites),
                  ),
                  const SizedBox(width: 2),
                  _NotificationButton(
                    count: unreadNotificationCount,
                    onTap: onNotifications,
                  ),
                  const SizedBox(width: 4),
                  _ProfileButton(user: user, onTap: onProfile),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesButton extends StatelessWidget {
  const _FavoritesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return _Button(
      key: const ValueKey('favorites-button'),
      tooltip: 'profile.favorites'.tr,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: _TopActionSurface(
        child: Icon(
          Icons.favorite_outline_rounded,
          size: 23,
          color: color.withValues(alpha: 0.84),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _Button(
          key: const ValueKey('notifications-button'),
          tooltip: 'common.notifications'.tr,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: _TopActionSurface(
            child: Icon(
              count > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 23,
              color: colors.onSurface.withValues(alpha: 0.84),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFD93838),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                count > 99 ? '99+' : '${count.clamp(1, 99)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.user, required this.onTap});

  final AuthenticatedUser? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message:
        user?.displayName == null
            ? 'common.open_profile'.tr
            : 'common.user_profile'.trParams({'name': user!.displayName}),
    child: InkResponse(
      key: const ValueKey('profile-button'),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      radius: 22,
      child: SizedBox(
        width: 42,
        height: 44,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AuthenticatedUserAvatar(user: user, size: 34),
          ),
        ),
      ),
    ),
  );
}

class _TopActionSurface extends StatelessWidget {
  const _TopActionSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.90),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.68),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(width: 42, height: 44, child: Center(child: child)),
    ),
  );
}
