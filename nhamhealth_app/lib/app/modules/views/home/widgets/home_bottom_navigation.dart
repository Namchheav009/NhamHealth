import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/app_bottom_navigation.dart';
import '../../../controllers/home/home_controller.dart';

class HomeBottomNavigation extends GetView<HomeController> {
  const HomeBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) => Obx(
    () => AppBottomNavigation(
      selectedIndex: controller.selectedBottomIndex.value,
      onSelect: controller.selectBottomMenu,
    ),
  );
}
