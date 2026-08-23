import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/home/home_controller.dart';
import 'widgets/ai_recommendation_card.dart';
import 'widgets/daily_summary_card.dart';
import 'widgets/greeting_section.dart';
import 'widgets/home_bottom_navigation.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/recommended_meal_card.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const double _maxContentWidth = AppSpacing.maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.homeBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: controller.refreshMeals,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: AppSpacing.pagePaddingWithNavigation,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxContentWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HomeHeader(),
                            const SizedBox(height: AppSpacing.topBarBottom),
                            Obx(
                              () => LoadingContentTransition(
                                isLoading: controller.isLoading.value &&
                                    controller.dashboard.value == null,
                                loading: const PageSkeleton.home(),
                                content: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HomeSearchBar(),
                                    SizedBox(height: 16),
                                    GreetingSection(),
                                    SizedBox(height: 16),
                                    AiRecommendationCard(),
                                    SizedBox(height: 16),
                                    DailySummaryCard(),
                                    SizedBox(height: 18),
                                    _RecommendedMealsSection(),
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
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: AppSpacing.navigationMargin,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: const HomeBottomNavigation(),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedMealsSection extends GetView<HomeController> {
  const _RecommendedMealsSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meals = controller.dashboard.value?.recommendedMeals ?? const [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recommended Meals',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (meals.isNotEmpty)
                TextButton(
                  onPressed: controller.getRecommendation,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Refresh',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (controller.isRecommendedMealsLoading.value && meals.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primaryGreen,
                backgroundColor: AppColors.softGreen,
              ),
            )
          else if (meals.isNotEmpty) ...[
            const SizedBox(height: 7),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 600
                    ? (constraints.maxWidth - 28) / 5
                    : 132.0;
                return SizedBox(
                  height: 176,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: meals.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (_, index) => SizedBox(
                      width: cardWidth,
                      child: RecommendedMealCard(
                      meal: meals[index],
                      onTap: () => controller.openMeals(),
                      isFavorite: controller.favoriteMealIds.contains(
                        meals[index].id,
                      ),
                      onFavorite:
                          () => controller.toggleMealFavorite(meals[index].id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 8),
              child: Text(
                'Choose a mood, then tap Get Recommendation to see personalized meals.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
              ),
            ),
        ],
      );
    });
  }
}
