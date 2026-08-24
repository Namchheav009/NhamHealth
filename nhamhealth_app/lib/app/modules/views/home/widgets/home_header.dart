import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/nham_app_bar.dart';
import '../../../controllers/home/home_controller.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) => Obx(() => NhamAppBar(
    user: controller.authenticatedUser.value,
    unreadNotificationCount: controller.unreadNotificationCount.value,
    onNotifications: controller.openNotifications,
    onProfile: controller.openProfile,
  ));
}
