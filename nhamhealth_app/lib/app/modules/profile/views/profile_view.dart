import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

import '../controllers/profile_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_top_bar.dart';
import 'widgets/health_stats_card.dart';
import 'widgets/insight_card.dart';
import 'widgets/profile_bottom_navigation.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_post_card.dart';
import 'widgets/progress_card.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFFBFC),
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: controller.refreshProfile,
            color: const Color(0xFF009B3E),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: AppSpacing.pagePaddingWithNavigation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  Obx(() {
                    final message = controller.errorMessage.value;
                    if (message == null) return const SizedBox.shrink();
                    return _ProfileErrorBanner(
                      message: message,
                      onRetry: controller.loadProfile,
                    );
                  }),
                  const SizedBox(height: 12),
                  Obx(
                    () => LoadingContentTransition(
                      isLoading:
                          controller.isLoading.value &&
                          controller.dashboard.value == null,
                      loading: const PageSkeleton.profile(),
                      content: const Column(
                              children: [
                                ProfileHeader(),
                                SizedBox(height: 8),
                                HealthStatsCard(),
                                SizedBox(height: 8),
                                ProgressCard(),
                                SizedBox(height: 8),
                                InsightCard(),
                                SizedBox(height: 8),
                                ProfilePostCard(),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(25, 0, 25, 14),
        child: ProfileBottomNavigation(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Obx(() => AppTopBar(
      user: controller.authenticatedUser.value,
      unreadNotificationCount: controller.unreadNotificationCount.value,
      onFavorites: () => Get.toNamed<void>(AppRoutes.favorites),
      onNotifications: controller.openNotifications,
      menuActions: [
        AppTopBarAction(label: 'Edit Profile', icon: Icons.edit_outlined, onTap: controller.editProfile),
        AppTopBarAction(label: 'Notifications', icon: Icons.notifications_none_rounded, onTap: controller.openNotifications),
        AppTopBarAction(label: 'Settings', icon: Icons.settings_outlined, onTap: controller.openSettings),
        AppTopBarAction(label: 'Logout', icon: Icons.logout_rounded, color: const Color(0xFFD32F2F), dividerBefore: true, onTap: controller.requestLogout),
      ],
    ));
  }
}

class _ProfileErrorBanner extends StatelessWidget {
  const _ProfileErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD84A4A), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
