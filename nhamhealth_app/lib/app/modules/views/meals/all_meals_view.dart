import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/meals/meal_controller.dart';
import 'widgets/meal_card.dart';
import 'widgets/meal_category.dart';
import 'widgets/meal_search_bar.dart';

class AllMealsView extends GetView<MealController> {
  const AllMealsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: controller.refreshPage,
              child: Scrollbar(
                interactive: true,
                radius: const Radius.circular(8),
                thickness: 3,
                child: CustomScrollView(
                  primary: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _header(context)),
                    SliverToBoxAdapter(child: _controls(context)),
                    Obx(() => _mealContent(context)),
                    const SliverToBoxAdapter(child: SizedBox(height: 36)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontalFor(context),
          AppSpacing.pageTop,
          AppSpacing.pageHorizontalFor(context),
          18,
        ),
        child: Row(
          children: [
            AppBackButton(onPressed: Get.back),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All meals'.tr,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                  Text(
                    'Find something healthy and delicious'.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _controls(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontalFor(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MealSearchBar(),
            const SizedBox(height: 14),
            const MealCategory(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );

  Widget _mealContent(BuildContext context) {
    final meals = controller.filteredMeals;
    if (controller.isLoading.value && controller.meals.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontalFor(context),
              ),
              child: const PageSkeleton.allMeals(),
            ),
          ),
        ),
      );
    }
    if (controller.errorMessage.value != null && controller.meals.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageState(
          icon: Icons.cloud_off_rounded,
          title: 'Meals unavailable',
          message: controller.errorMessage.value!,
          actionLabel: 'Try again',
          onAction: controller.loadMeals,
        ),
      );
    }
    if (meals.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageState(
          icon: Icons.search_off_rounded,
          title: 'No meals found',
          message: 'Try a different search, category, or filter.',
          actionLabel: 'Clear filters',
          onAction: () {
            controller.clearSearch();
            controller.clearMealFilters();
          },
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns =
            width >= 900
                ? 4
                : width >= 650
                ? 3
                : 2;
        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontalFor(context),
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 232,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final meal = meals[index];
              return MealCard(
                key: ValueKey('all-meal-${meal.id}'),
                meal: meal,
                onTap: () => controller.openFoodDetail(meal),
                onFavorite: () => controller.toggleMealFavorite(meal),
              );
            }, childCount: meals.length),
          ),
        );
      },
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: context.appMutedText),
          const SizedBox(height: 14),
          Text(
            title.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMutedText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel.tr)),
        ],
      ),
    ),
  );
}
