import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/app_search_bar.dart';
import '../../../controllers/meals/meal_controller.dart';
import 'meal_filter_sheet.dart';

class MealSearchBar extends GetView<MealController> {
  const MealSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppSearchBar(
        hintText: 'meals.search_meals_and_healthy_ideas',
        controller: controller.searchController,
        onChanged: controller.updateSearch,
        onSubmitted: controller.updateSearch,
        showClear: controller.searchQuery.value.isNotEmpty,
        onClear: controller.clearSearch,
        trailing: const MealFilterButton(),
      ),
    );
  }
}
