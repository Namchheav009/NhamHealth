import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../auth/models/authenticated_user_model.dart';
import '../../controllers/home_controller.dart';
import 'authenticated_user_avatar.dart';
import 'inner_shadow.dart';

class HomeProfileContent extends GetView<HomeController> {
  const HomeProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.authenticatedUser.value;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 108),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey<String>('profile-back-button'),
                  onPressed: () => controller.selectBottomMenu(0),
                  color: AppColors.primaryText,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                const Expanded(
                  child: Text(
                    'My Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 18),
            _IdentityCard(user: user),
            const SizedBox(height: 16),
            _AccountCard(
              email: user?.email ?? 'No email available',
              role: user?.role ?? 'USER',
              userId: user?.id,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              key: const ValueKey<String>('profile-logout-button'),
              onPressed:
                  controller.isLoggingOut.value ? null : controller.logout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(
                controller.isLoggingOut.value ? 'Logging out…' : 'Logout',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F),
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AuthenticatedUser? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.softPink,
            AppColors.cardSurface,
            AppColors.softGreen,
          ],
        ),
        boxShadow: AppShadows.surface,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          child: Column(
            children: [
              AuthenticatedUserAvatar(user: user, size: 92),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'Nham Health User',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user?.email ?? 'Sign in to view your profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.email,
    required this.role,
    required this.userId,
  });

  final String email;
  final String role;
  final int? userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.surface,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            children: [
              _ProfileRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
              ),
              const Divider(height: 1, color: AppColors.border),
              _ProfileRow(
                icon: Icons.verified_user_outlined,
                label: 'Account type',
                value: _formatRole(role),
              ),
              if (userId != null) ...[
                const Divider(height: 1, color: AppColors.border),
                _ProfileRow(
                  icon: Icons.badge_outlined,
                  label: 'User ID',
                  value: '#$userId',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatRole(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'User';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
