import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_search_bar.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/nham_app_bar.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../widgets/scroll_aware_scaffold.dart';
import '../../controllers/meals/meal_controller.dart';
import '../../models/meals/meal_model.dart';
import 'all_meals_view.dart';
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
      child: ScrollAwareScaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontalFor(context),
                    AppSpacing.pageTop,
                    AppSpacing.pageHorizontalFor(context),
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxWideContentWidth,
                      ),
                      child: Obx(
                        () => NhamAppBar(
                          user: controller.authenticatedUser.value,
                          unreadNotificationCount:
                              controller.unreadNotificationCount.value,
                          onNotifications: controller.openNotifications,
                          onProfile: controller.openProfile,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.topBarBottom),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: controller.refreshPage,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: AppSpacing.pagePaddingWithNavigationFor(
                        context,
                      ).copyWith(top: 0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSpacing.maxWideContentWidth,
                          ),
                          child: Obx(
                            () => LoadingContentTransition(
                              isLoading: controller.isLoading.value,
                              loading: const PageSkeleton.meals(),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Obx(
                                    () => AppSearchBar(
                                      hintText:
                                          'meals.search_meals_and_healthy_ideas',
                                      controller: controller.searchController,
                                      onChanged: controller.updateSearch,
                                      showClear:
                                          controller
                                              .searchQuery
                                              .value
                                              .isNotEmpty,
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
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: AppSpacing.navigationMargin,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxNavigationWidth,
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
        return const PageSkeleton.allMeals();
      }
      final error = controller.errorMessage.value;
      if (error != null && controller.meals.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(
                error.trOrSelf,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Get.context?.appMutedText,
                  fontSize: 12,
                ),
              ),
              TextButton(
                onPressed: controller.loadMeals,
                child: Text('common.try_again'.tr),
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
              'meals.empty_search'.tr,
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
                    ? 'meals.popular'
                    : 'Search results',
            onSeeAll: () {
              controller.showAllMeals();
              Get.to<void>(
                () => const AllMealsView(),
                transition: Transition.rightToLeft,
              );
            },
          ),
          const SizedBox(height: 10),
          _buildPopularMeals(meals),
          const SizedBox(height: 14),
          MealSectionHeader(title: 'meals.ideas_for_you'),
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
                      ? 'meals.ai_ranking_description'.tr
                      : controller.isIdeasLoading.value
                      ? 'meals.creating_personalized'.tr
                      : 'meals.general_ideas_fallback'.tr,
                  style: TextStyle(
                    color: Get.context?.appMutedText,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _buildIdeaMeals(ideaMeals),
        ],
      );
    });
  }

  Widget _buildIdeaMeals(Iterable<MealModel> ideaMeals) {
    final list = ideaMeals.toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= AppSpacing.twoColumnBreakpoint;

        if (!isTablet) {
          return Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                MealIdeaCard(
                  key: ValueKey<String>('meal-idea-${list[i].id}'),
                  meal: list[i],
                  onTap: () => controller.openFoodDetail(list[i]),
                  onFavorite: () => controller.toggleMealFavorite(list[i]),
                ),
                if (i < list.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final meal in list)
              SizedBox(
                width: cardWidth,
                child: MealIdeaCard(
                  key: ValueKey<String>('meal-idea-${meal.id}'),
                  meal: meal,
                  onTap: () => controller.openFoodDetail(meal),
                  onFavorite: () => controller.toggleMealFavorite(meal),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPopularMeals(List<MealModel> meals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppSpacing.tabletBreakpoint;
        final cardWidth =
            isWide
                ? 210.0
                : ((constraints.maxWidth - 10) / 2.04).clamp(145.0, 174.0);
        final cardHeight = isWide ? 190.0 : 174.0;
        final itemGap = isWide ? 14.0 : 12.0;

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            key: const ValueKey('popular-meals-list'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: meals.length,
            separatorBuilder: (_, _) => SizedBox(width: itemGap),
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
