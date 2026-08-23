import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';

class HomeSearchBar extends GetView<HomeController> {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: AppShadows.search,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.secondaryText,
                size: 25,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: TextField(
                  onSubmitted: (query) => controller.openMeals(query: query),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryText,
                  ),
                  cursorColor: AppColors.primaryGreen,
                  decoration: const InputDecoration(
                    hintText: 'Search for meals, tips or healthy groceries',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
