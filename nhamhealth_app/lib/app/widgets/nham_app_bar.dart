import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/models/auth/authenticated_user_model.dart';
import '../modules/views/home/widgets/authenticated_user_avatar.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'language_flag.dart';

class NhamAppBar extends StatelessWidget {
  const NhamAppBar({
    super.key,
    required this.user,
    required this.unreadNotificationCount,
    required this.onNotifications,
    required this.onProfile,
  });

  final AuthenticatedUser? user;
  final int unreadNotificationCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
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
                _ProfileButton(user: user, onTap: onProfile),
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

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.user, required this.onTap});

  final AuthenticatedUser? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message:
        user?.displayName == null
            ? 'Open profile'
            : '${user!.displayName} · Profile',
    child: InkResponse(
      key: const ValueKey('profile-button'),
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 42,
        height: 44,
        child: Center(child: AuthenticatedUserAvatar(user: user, size: 36)),
      ),
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
