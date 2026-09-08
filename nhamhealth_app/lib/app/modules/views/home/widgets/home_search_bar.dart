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
      hintText: 'home.search_for_meals_tips_or_healthy_groceries',
      useSoftHomeStyle: true,
      onSubmitted: (query) => controller.openMeals(query: query),
      trailing: IconButton(
        tooltip: 'home.browse_filter_meals'.tr,
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
