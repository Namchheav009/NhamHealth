import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../widgets/app_background.dart';
import '../controllers/home_controller.dart';
import 'widgets/ai_recommendation_card.dart';
import 'widgets/daily_summary_card.dart';
import 'widgets/greeting_section.dart';
import 'widgets/home_bottom_navigation.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/recommended_meal_card.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

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
                child: Obx(
                  () => LoadingContentTransition(
                    isLoading:
                        controller.isLoading.value &&
                        controller.dashboard.value == null,
                    loading: const PageSkeleton.home(),
                    content: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HomeHeader(),
                              SizedBox(height: 16),
                              HomeSearchBar(),
                              SizedBox(height: 14),
                              GreetingSection(),
                              SizedBox(height: 14),
                              AiRecommendationCard(),
                              SizedBox(height: 14),
                              DailySummaryCard(),
                              SizedBox(height: 12),
                              _RecommendedMealsSection(),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(25, 0, 25, 14),
          child: HomeBottomNavigation(),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
                  child: const Text('Refresh', style: TextStyle(fontSize: 10)),
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
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: meals.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder:
                    (_, index) => RecommendedMealCard(meal: meals[index]),
              ),
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
