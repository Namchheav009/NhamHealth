import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../auth/models/authenticated_user_model.dart';
import '../../controllers/home_controller.dart';
import 'authenticated_user_avatar.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
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
          _HeaderButton(
            onTap: controller.openFavorites,
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.favoriteRed,
              size: 28,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderButton(
                onTap: controller.openNotifications,
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF333333),
                  size: 27,
                ),
              ),
              Positioned(
                right: 3,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Obx(() => _ProfileMenu(user: controller.authenticatedUser.value)),
        ],
      ),
    );
  }
}

class _ProfileMenu extends GetView<HomeController> {
  const _ProfileMenu({required this.user});

  final AuthenticatedUser? user;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProfileMenuAction>(
      key: const ValueKey<String>('profile-menu-button'),
      tooltip: user == null ? 'Open profile menu' : user!.displayName,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) {
        switch (action) {
          case _ProfileMenuAction.profile:
            controller.openProfile();
          case _ProfileMenuAction.logout:
            controller.logout();
        }
      },
      itemBuilder:
          (context) => [
            if (user != null)
              PopupMenuItem<_ProfileMenuAction>(
                enabled: false,
                child: _SignedInUser(user: user!),
              ),
            if (user != null) const PopupMenuDivider(height: 1),
            const PopupMenuItem<_ProfileMenuAction>(
              value: _ProfileMenuAction.profile,
              child: _ProfileMenuRow(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
              ),
            ),
            const PopupMenuDivider(height: 1),
            const PopupMenuItem<_ProfileMenuAction>(
              value: _ProfileMenuAction.logout,
              child: _ProfileMenuRow(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: Color(0xFFD32F2F),
              ),
            ),
          ],
      child: AuthenticatedUserAvatar(user: user),
    );
  }
}

class _SignedInUser extends StatelessWidget {
  const _SignedInUser({required this.user});

  final AuthenticatedUser user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF252525),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
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
}

enum _ProfileMenuAction { profile, logout }

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF333333),
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 23,
      child: SizedBox(width: 42, height: 46, child: Center(child: child)),
    );
  }
}
