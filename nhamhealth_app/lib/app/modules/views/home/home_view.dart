import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/home/home_controller.dart';
import 'widgets/ai_recommendation_card.dart';
import 'widgets/daily_summary_card.dart';
import 'widgets/greeting_section.dart';
import 'widgets/home_bottom_navigation.dart';
import 'widgets/home_chatbot_button.dart';
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
                            isLoading:
                                controller.isLoading.value &&
                                controller.dashboard.value == null,
                            loading: const PageSkeleton.home(),
                            content: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HomeSearchBar(),
                                SizedBox(height: 14),
                                GreetingSection(),
                                SizedBox(height: 14),
                                AiRecommendationCard(),
                                SizedBox(height: 14),
                                DailySummaryCard(),
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
        floatingActionButton: const HomeChatbotButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (meals.isNotEmpty)
                  TextButton(
                    onPressed:
                        controller.isRecommendedMealsLoading.value
                            ? null
                            : controller.getRecommendation,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      controller.isRecommendedMealsLoading.value
                          ? 'Refreshing…'
                          : 'Refresh',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (meals.isNotEmpty) ...[
              const SizedBox(height: 7),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth =
                      constraints.maxWidth >= 600
                          ? (constraints.maxWidth - 28) / 5
                          : 100.0;
                  return SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: meals.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder:
                          (_, index) => SizedBox(
                            width: cardWidth,
                            child: RecommendedMealCard(
                              meal: meals[index],
                              onTap: () => controller.openMeals(),
                              isFavorite: controller.favoriteMealIds.contains(
                                meals[index].id,
                              ),
                              onFavorite:
                                  () => controller.toggleMealFavorite(
                                    meals[index].id,
                                  ),
                            ),
                          ),
                    ),
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 6),
              const Text(
                'Choose a mood, then tap Get Recommendation to see personalized meals.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
