import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';
import '../../../widgets/app_top_bar.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/meals/meal_controller.dart';
import '../home/widgets/inner_shadow.dart';
import 'widgets/meal_bottom_navigation.dart';
import 'widgets/meal_card.dart';
import 'widgets/meal_category.dart';
import 'widgets/meal_slideshow.dart';

class MealView extends GetView<MealController> {
  const MealView({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.homeBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: controller.loadMeals,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(27, 24, 27, 125),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Obx(
                            () => AppTopBar(
                              user: controller.authenticatedUser.value,
                              unreadNotificationCount:
                                  controller.unreadNotificationCount.value,
                              onFavorites: controller.openFavorites,
                              onNotifications: controller.openNotifications,
                              menuActions: [
                                AppTopBarAction(
                                  label: 'My Profile',
                                  icon: Icons.person_outline_rounded,
                                  onTap: controller.openProfile,
                                ),
                                AppTopBarAction(
                                  label: 'Logout',
                                  icon: Icons.logout_rounded,
                                  color: const Color(0xFFD32F2F),
                                  dividerBefore: true,
                                  onTap: controller.logout,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Obx(
                            () => controller.isLoading.value &&
                                    controller.meals.isEmpty
                                ? const PageSkeleton.meals()
                                : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSearch(),
                                    const SizedBox(height: 14),
                                    const MealCategory(),
                                    const SizedBox(height: 22),
                                    const MealSlideShow(),
                                    const SizedBox(height: 23),
                                    _buildMealGrid(),
                                  ],
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

        // YOUR EXISTING NAVIGATION
        bottomNavigationBar: const SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(25, 0, 25, 14),
          child: MealBottomNavigation(),
        ),
      ),
    );
  }

  Widget _buildSearch() {
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
          padding: const EdgeInsets.only(left: 20, right: 8),
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
                  controller: controller.searchController,
                  onChanged: controller.updateSearch,
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
              Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      controller.searchQuery.value.isEmpty
                          ? const SizedBox(width: 36)
                          : IconButton(
                            key: const ValueKey('clear-meal-search'),
                            onPressed: controller.clearSearch,
                            tooltip: 'Clear search',
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 19,
                              color: AppColors.secondaryText,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealGrid() {
    return Obx(
      () {
        final meals = controller.filteredMeals;
        if (controller.isLoading.value && controller.meals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }
        final error = controller.errorMessage.value;
        if (error != null && controller.meals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: controller.loadMeals,
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        if (meals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 42),
            child: Center(
              child: Text(
                'No meals found. Try another search or category.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 330 ? 2 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
                childAspectRatio: columns == 3 ? 0.67 : 0.72,
              ),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return MealCard(
                  meal: meal,
                  onFavorite: () => controller.toggleFavorite(
                    controller.meals.indexOf(meal),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
