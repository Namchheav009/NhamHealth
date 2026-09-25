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
import 'widgets/home_quick_actions.dart';
import 'widgets/recommended_meal_card.dart';
import 'widgets/time_greeting.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const double _maxContentWidth = AppSpacing.maxWideContentWidth;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: AppBackground(
        child: ScrollAwareScaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: SafeArea(
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
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: controller.refreshMeals,
                    child: SingleChildScrollView(
                      primary: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppSpacing.pagePaddingFor(
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
            key: ValueKey<String>('home-mobile-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(child: TimeGreeting()),
              SizedBox(height: 12),
              RepaintBoundary(child: GreetingSection()),
              SizedBox(height: 16),
              RepaintBoundary(child: AiRecommendationCard()),
              SizedBox(height: 12),
              RepaintBoundary(child: HomeQuickActions()),
              SizedBox(height: 12),
              RepaintBoundary(child: DailySummaryCard()),
              RepaintBoundary(child: _RecommendedMealsSection()),
            ],
          );
        }

        return const Column(
          key: ValueKey<String>('home-tablet-layout'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(child: TimeGreeting()),
            SizedBox(height: 16),
            RepaintBoundary(child: GreetingSection()),
            SizedBox(height: 18),
            RepaintBoundary(child: AiRecommendationCard()),
            SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: RepaintBoundary(child: HomeQuickActions()),
                ),
                SizedBox(width: 18),
                Expanded(
                  flex: 6,
                  child: RepaintBoundary(child: DailySummaryCard()),
                ),
              ],
            ),
            RepaintBoundary(child: _RecommendedMealsSection()),
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
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.appSoftGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 9),
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
                          fontSize: 15,
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
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home.see_more'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            if (meals.isNotEmpty) ...[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final cardWidth =
                      isWide
                          ? 210.0
                          : ((constraints.maxWidth - 10) / 2.04).clamp(
                            145.0,
                            174.0,
                          );
                  final cardHeight = isWide ? 190.0 : 174.0;
                  final itemGap = isWide ? 14.0 : 10.0;
                  return SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: meals.length,
                      separatorBuilder: (_, _) => SizedBox(width: itemGap),
                      itemBuilder:
                          (_, index) => RecommendedMealCard(
                            width: cardWidth,
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
