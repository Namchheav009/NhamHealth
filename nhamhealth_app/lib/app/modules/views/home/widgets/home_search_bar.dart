import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_search_bar.dart';
import '../../../controllers/home/home_controller.dart';

class HomeSearchBar extends GetView<HomeController> {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      hintText: 'Search for meals, tips or healthy groceries',
      useSoftHomeStyle: true,
      onSubmitted: (query) => controller.openMeals(query: query),
      trailing: IconButton(
        tooltip: 'Browse and filter meals'.tr,
        onPressed: controller.openMeals,
        icon: const Icon(
          Icons.tune_rounded,
          color: AppColors.primaryGreen,
          size: 22,
        ),
      ),
    );
  }
}
