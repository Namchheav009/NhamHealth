import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

import '../../controllers/profile/profile_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/nham_app_bar.dart';
import 'widgets/health_stats_card.dart';
import 'widgets/insight_card.dart';
import '../home/widgets/home_bottom_navigation.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_post_card.dart';

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
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
                  const SizedBox(height: AppSpacing.topBarBottom),
                  Obx(
                    () => LoadingContentTransition(
                      isLoading:
                          controller.isLoading.value &&
                          controller.dashboard.value == null,
                      loading: const PageSkeleton.profile(),
                      content: const Column(
                        children: [
                          ProfileHeader(),
                          SizedBox(height: 14),
                          HealthStatsCard(),
                          SizedBox(height: 14),
                          InsightCard(),
                          SizedBox(height: 22),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Recent activity',
                              style: TextStyle(
                                color: Color(0xFF26322B),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
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
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: AppSpacing.navigationMargin,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Obx(
              () => AppBottomNavigation(
                selectedIndex: controller.selectedNavIndex.value,
                onSelect: controller.changeNavigation,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Obx(
      () => NhamAppBar(
        user: controller.authenticatedUser.value,
        unreadNotificationCount: controller.unreadNotificationCount.value,
        onFavorites: () => Get.toNamed<void>(AppRoutes.favorites),
        onNotifications: controller.openNotifications,
        onProfile: controller.openProfile,
        onSettings: controller.openSettings,
        onLogout: controller.requestLogout,
      ),
    );
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
