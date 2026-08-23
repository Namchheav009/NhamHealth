import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/models/auth/authenticated_user_model.dart';
import '../modules/views/home/widgets/authenticated_user_avatar.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'language_flag.dart';

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

class NhamAppBar extends StatelessWidget {
  const NhamAppBar({
    super.key,
    required this.user,
    required this.unreadNotificationCount,
    required this.onFavorites,
    required this.onNotifications,
    required this.onProfile,
    required this.onSettings,
    required this.onLogout,
  });

  final AuthenticatedUser? user;
  final int unreadNotificationCount;
  final VoidCallback onFavorites;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.2,
    child: SizedBox(
      width: double.infinity,
      height: AppSpacing.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/logo.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 7),
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
            Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4ECE7)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D244C35),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LanguageButton(),
                _NotificationButton(
                  count: unreadNotificationCount,
                  onTap: onNotifications,
                ),
                _ProfileMenu(
                  user: user,
                  actions: [
                    AppTopBarAction(
                      label: 'My profile',
                      icon: Icons.person_outline_rounded,
                      onTap: onProfile,
                    ),
                    AppTopBarAction(
                      label: 'Favorites',
                      icon: Icons.favorite_border_rounded,
                      color: AppColors.favoriteRed,
                      onTap: onFavorites,
                    ),
                    AppTopBarAction(
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: onSettings,
                    ),
                    AppTopBarAction(
                      label: 'Log out',
                      icon: Icons.logout_rounded,
                      color: const Color(0xFFD32F2F),
                      dividerBefore: true,
                      onTap: onLogout,
                    ),
                  ],
                ),
              ],
            ),
            ),
          ],
        ),
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
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F7F3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            count > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            size: 23,
            color: Color(0xFF333333),
          ),
        ),
      ),
      Positioned(
        right: 1,
        top: -1,
        child: Container(
          constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFD32F2F),
            shape: BoxShape.circle,
          ),
          child: Text(
            count > 99 ? '99+' : '${count.clamp(0, 99)}',
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

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final locale = Get.locale ?? Localizations.localeOf(context);
    final isKhmer = locale.languageCode == 'km';

    return Tooltip(
      key: const ValueKey('language-page-button'),
      message: 'Change language',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (Get.currentRoute != AppRoutes.language) {
              Get.toNamed<void>(AppRoutes.language);
            }
          },
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            width: 42,
            height: 44,
            child: Center(
              child: LanguageFlag(
                languageCode: isKhmer ? 'km' : 'en',
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    constraints: const BoxConstraints(minWidth: 230, maxWidth: 270),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: actions[i].color.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      actions[i].icon,
                      size: 19,
                      color: actions[i].color,
                    ),
                  ),
                  const SizedBox(width: 11),
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
      width: 42,
      height: 44,
      child: Center(
        child: AuthenticatedUserAvatar(user: user, size: 36),
      ),
    ),
  );
}

class _UserSummary extends StatelessWidget {
  const _UserSummary({required this.user});
  final AuthenticatedUser user;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Row(
      children: [
        AuthenticatedUserAvatar(
          user: user,
          size: 38,
          showOnlineStatus: false,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
      radius: 22,
      child: SizedBox(width: 42, height: 44, child: Center(child: child)),
    ),
  );
}
