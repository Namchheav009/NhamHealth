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
import 'widgets/time_greeting.dart';

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
              RepaintBoundary(child: TimeGreeting()),
              SizedBox(height: 14),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RepaintBoundary(child: TimeGreeting()),
                      SizedBox(height: 16),
                      RepaintBoundary(child: HomeSearchBar()),
                      SizedBox(height: 16),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.appSoftGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 20,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended for You'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Picked for your mood and wellness goals'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (meals.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth =
                      constraints.maxWidth >= 600
                          ? (constraints.maxWidth - 36) / 4
                          : 142.0;
                  return SizedBox(
                    height: 184,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: meals.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
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
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appSubtleSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.appBorder.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Choose a mood, then tap Get Recommendation to see personalized meals.'
                            .tr,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
