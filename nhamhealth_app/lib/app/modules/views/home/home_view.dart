import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
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
                maxWidth: AppSpacing.maxNavigationWidth,
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
              RepaintBoundary(child: GreetingSection()),
              SizedBox(height: 14),
              RepaintBoundary(child: _MealPlannerCard()),
              SizedBox(height: 14),
              RepaintBoundary(child: DailySummaryCard()),
              SizedBox(height: 14),
              RepaintBoundary(child: AiRecommendationCard()),
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
                      RepaintBoundary(child: _MealPlannerCard()),
                      SizedBox(height: 16),
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

class _MealPlannerCard extends StatelessWidget {
  const _MealPlannerCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('home-meal-planner-card'),
        onTap: () => Get.toNamed<void>(AppRoutes.mealPlanner),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.appSoftGreen, context.appElevatedSurface],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.plan_your_week'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'planner.home_description'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
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
                        'home.recommended_for_you'.tr,
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
                        'home.picked_for_your_mood_and_wellness_goals'.tr,
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
                TextButton(
                  onPressed: () => controller.openMeals(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'home.see_more'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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
                              onTap:
                                  () => controller.openRecommendedMeal(
                                    meals[index],
                                  ),
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
                        'home.choose_a_mood_then_tap_get_recommendation_to_see_personalized_meals'
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
