import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    );
  }
}
