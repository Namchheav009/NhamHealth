import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../widgets/scroll_aware_scaffold.dart';
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

  static const double _maxContentWidth = AppSpacing.maxWideContentWidth;

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
                        maxWidth: _maxContentWidth,
                      ),
                      child: const RepaintBoundary(child: HomeHeader()),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.topBarBottom),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: controller.refreshMeals,
                    child: SingleChildScrollView(
                      primary: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppSpacing.pagePaddingWithNavigationFor(
                        context,
                      ).copyWith(top: 0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxContentWidth,
                          ),
                          child: Obx(
                            () => LoadingContentTransition(
                              isLoading:
                                  controller.isLoading.value &&
                                  controller.dashboard.value == null,
                              loading: const PageSkeleton.home(),
                              content: const _HomeDashboardContent(),
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
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: const HomeBottomNavigation(),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSpacing.twoColumnBreakpoint) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(child: HomeSearchBar()),
              SizedBox(height: 14),
              RepaintBoundary(child: GreetingSection()),
              SizedBox(height: 14),
              RepaintBoundary(child: AiRecommendationCard()),
              SizedBox(height: 14),
              RepaintBoundary(child: DailySummaryCard()),
              RepaintBoundary(child: _RecommendedMealsSection()),
            ],
          );
        }

        return const Column(
          key: ValueKey<String>('home-tablet-layout'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(child: HomeSearchBar()),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      RepaintBoundary(child: GreetingSection()),
                      SizedBox(height: 16),
                      RepaintBoundary(child: AiRecommendationCard()),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      RepaintBoundary(child: DailySummaryCard()),
                      RepaintBoundary(child: _RecommendedMealsSection()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
                Expanded(
                  child: Text(
                    'Recommended Meals'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
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
                          ? 'Refreshing…'.tr
                          : 'Refresh'.tr,
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
              Text(
                'Choose a mood, then tap Get Recommendation to see personalized meals.'
                    .tr,
                style: TextStyle(
                  color: context.appMutedText,
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
