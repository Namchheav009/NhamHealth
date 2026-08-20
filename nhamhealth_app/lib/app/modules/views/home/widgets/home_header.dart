import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/app_top_bar.dart';
import '../../../controllers/home/home_controller.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) => Obx(() => AppTopBar(
    user: controller.authenticatedUser.value,
    unreadNotificationCount: controller.unreadNotificationCount.value,
    onFavorites: controller.openFavorites,
    onNotifications: controller.openNotifications,
    menuActions: [
      AppTopBarAction(label: 'My Profile', icon: Icons.person_outline_rounded, onTap: controller.openProfile),
      AppTopBarAction(label: 'Settings', icon: Icons.settings_outlined, onTap: controller.openSettings),
      AppTopBarAction(label: 'Logout', icon: Icons.logout_rounded, color: const Color(0xFFD32F2F), dividerBefore: true, onTap: controller.logout),
    ],
  ));
}
