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
import '../../models/meals/meal_model.dart';
import 'widgets/meal_card.dart';
import 'widgets/meal_category.dart';
import 'widgets/meal_filter_sheet.dart';
import 'widgets/meal_idea_card.dart';
import 'widgets/meal_section_header.dart';
import 'widgets/meal_slideshow.dart';

class MealView extends GetView<MealController> {
  const MealView({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: controller.refreshPage,
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
                                Obx(
                                  () => AppSearchBar(
                                    hintText: 'Search meals and healthy ideas',
                                    controller: controller.searchController,
                                    onChanged: controller.updateSearch,
                                    showClear:
                                        controller.searchQuery.value.isNotEmpty,
                                    onClear: controller.clearSearch,
                                    trailing: const MealFilterButton(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const MealCategory(),
                                const SizedBox(height: 16),
                                const MealSlideShow(),
                                const SizedBox(height: 24),
                                _buildMealSections(),
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

  Widget _buildMealSections() {
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
              'No meals found. Try another search.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Get.context?.appMutedText, fontSize: 13),
            ),
          ),
        );
      }

      final personalizedIdeas = controller.personalizedIdeas;
      final ideaMeals =
          personalizedIdeas.isNotEmpty
              ? personalizedIdeas.take(3)
              : meals.length > 3
              ? meals.skip(3).take(3)
              : meals.take(3);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MealSectionHeader(
            title:
                controller.searchQuery.value.isEmpty
                    ? 'Popular meals'
                    : 'Search results',
            onSeeAll: controller.showAllMeals,
          ),
          const SizedBox(height: 10),
          _buildPopularMeals(meals),
          const SizedBox(height: 24),
          MealSectionHeader(
            title: 'Ideas for you',
            actionLabel:
                controller.isIdeasLoading.value ? 'Refreshing…' : 'Refresh',
            actionEnabled: !controller.isIdeasLoading.value,
            onSeeAll: () => controller.loadPersonalizedIdeas(refresh: true),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                personalizedIdeas.isNotEmpty
                    ? Icons.auto_awesome_rounded
                    : Icons.info_outline_rounded,
                color:
                    personalizedIdeas.isNotEmpty
                        ? AppColors.primaryGreen
                        : Get.context?.appMutedText,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  personalizedIdeas.isNotEmpty
                      ? 'AI-ranked using saved height, weight and BMI when available, plus activity and daily nutrition goals for general wellness.'
                          .tr
                      : controller.isIdeasLoading.value
                      ? 'Creating your personalized meal ideas…'.tr
                      : 'Showing general ideas until AI personalization is available.'
                          .tr,
                  style: TextStyle(
                    color: Get.context?.appMutedText,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final meal in ideaMeals) ...[
            MealIdeaCard(
              key: ValueKey<String>('meal-idea-${meal.id}'),
              meal: meal,
              onTap: () => controller.openFoodDetail(meal),
              onFavorite: () => controller.toggleMealFavorite(meal),
            ),
            if (meal != ideaMeals.last) const SizedBox(height: 12),
          ],
        ],
      );
    });
  }

  Widget _buildPopularMeals(List<MealModel> meals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth >= AppSpacing.tabletBreakpoint
                ? 210.0
                : ((constraints.maxWidth - 12) / 2.08).clamp(150.0, 180.0);
        return SizedBox(
          height: 232,
          child: ListView.separated(
            key: const ValueKey('popular-meals-list'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: meals.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final meal = meals[index];
              return SizedBox(
                width: cardWidth,
                child: MealCard(
                  meal: meal,
                  onTap: () => controller.openFoodDetail(meal),
                  onFavorite: () => controller.toggleMealFavorite(meal),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
