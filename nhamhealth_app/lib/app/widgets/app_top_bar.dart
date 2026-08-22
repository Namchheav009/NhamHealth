import 'package:flutter/material.dart';

import '../modules/models/auth/authenticated_user_model.dart';
import '../modules/views/home/widgets/authenticated_user_avatar.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppTopBarAction {
  const AppTopBarAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF333333),
    this.dividerBefore = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool dividerBefore;
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.user,
    required this.unreadNotificationCount,
    required this.onFavorites,
    required this.onNotifications,
    required this.menuActions,
  });
  final AuthenticatedUser? user;
  final int unreadNotificationCount;
  final VoidCallback onFavorites;
  final VoidCallback onNotifications;
  final List<AppTopBarAction> menuActions;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: AppSpacing.topBarHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/logo.png',
            width: 52,
            height: 52,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryPink,
                ),
              ),
              Text(
                'HEALTH',
                style: TextStyle(
                  height: 1.05,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navigationGreen,
                ),
              ),
            ],
          ),
          const Spacer(),
          _Button(
            tooltip: 'Favorites',
            onTap: onFavorites,
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.favoriteRed,
              size: 28,
            ),
          ),
          _NotificationButton(
            count: unreadNotificationCount,
            onTap: onNotifications,
          ),
          const SizedBox(width: 4),
          _ProfileMenu(user: user, actions: menuActions),
        ],
      ),
    ),
  );
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      _Button(
        key: const ValueKey('notifications-button'),
        tooltip: 'Notifications',
        onTap: onTap,
        child: Icon(
          count > 0
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
          size: 27,
          color: const Color(0xFF333333),
        ),
      ),
      if (count > 0)
        Positioned(
          right: 1,
          top: -1,
          child: Container(
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryPink,
              shape: BoxShape.circle,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ],
  );
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.user, required this.actions});
  final AuthenticatedUser? user;
  final List<AppTopBarAction> actions;
  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    key: const ValueKey('profile-menu-button'),
    tooltip: user?.displayName ?? 'Open profile menu',
    position: PopupMenuPosition.under,
    offset: const Offset(0, 6),
    color: Colors.white,
    elevation: 10,
    constraints: const BoxConstraints(minWidth: 190),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    onSelected: (index) => actions[index].onTap(),
    itemBuilder:
        (_) => [
          if (user != null)
            PopupMenuItem<int>(
              enabled: false,
              child: _UserSummary(user: user!),
            ),
          if (user != null) const PopupMenuDivider(height: 1),
          for (var i = 0; i < actions.length; i++) ...[
            if (actions[i].dividerBefore) const PopupMenuDivider(height: 1),
            PopupMenuItem<int>(
              value: i,
              child: Row(
                children: [
                  Icon(actions[i].icon, size: 21, color: actions[i].color),
                  const SizedBox(width: 12),
                  Text(
                    actions[i].label,
                    style: TextStyle(
                      color: actions[i].color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
    child: SizedBox(
      width: 44,
      height: 48,
      child: Center(child: AuthenticatedUserAvatar(user: user)),
    ),
  );
}

class _UserSummary extends StatelessWidget {
  const _UserSummary({required this.user});
  final AuthenticatedUser user;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
        ),
      ],
    ),
  );
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
      radius: 23,
      child: SizedBox(width: 42, height: 46, child: Center(child: child)),
    ),
  );
}
