import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_search_bar.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/nham_app_bar.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/meals/meal_controller.dart';
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
        backgroundColor: context.appBackground,
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
                padding: AppSpacing.pagePaddingWithNavigationFor(context),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxWideContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => NhamAppBar(
                            user: controller.authenticatedUser.value,
                            unreadNotificationCount:
                                controller.unreadNotificationCount.value,
                            onNotifications: controller.openNotifications,
                            onProfile: controller.openProfile,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.topBarBottom),
                        Obx(
                          () => LoadingContentTransition(
                            isLoading:
                                controller.isLoading.value &&
                                controller.meals.isEmpty,
                            loading: const PageSkeleton.meals(),
                            content: Column(
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
                  selectedIndex: controller.selectedBottomIndex.value,
                  onSelect: controller.selectBottomMenu,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Obx(
      () => AppSearchBar(
        hintText: 'Search meals and healthy ideas',
        controller: controller.searchController,
        onChanged: controller.updateSearch,
        showClear: controller.searchQuery.value.isNotEmpty,
        onClear: controller.clearSearch,
      ),
    );
  }

  Widget _buildMealGrid() {
    return Obx(() {
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
                error.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Get.context?.appMutedText,
                  fontSize: 12,
                ),
              ),
              TextButton(
                onPressed: controller.loadMeals,
                child: Text('Try again'.tr),
              ),
            ],
          ),
        );
      }
      if (meals.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 42),
          child: Center(
            child: Text(
              'No meals found. Try another search or category.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Get.context?.appMutedText, fontSize: 13),
            ),
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = switch (constraints.maxWidth) {
            < 330 => 2,
            < AppSpacing.tabletBreakpoint => 3,
            < 840 => 4,
            _ => 5,
          };
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              childAspectRatio: columns == 2 ? 0.72 : 0.67,
            ),
            itemBuilder: (context, index) {
              final meal = meals[index];
              return MealCard(
                meal: meal,
                onTap: () => controller.openFoodDetail(meal),
                onFavorite:
                    () => controller.toggleFavorite(
                      controller.meals.indexOf(meal),
                    ),
              );
            },
          );
        },
      );
    });
  }
}
