import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../models/planner/meal_plan.dart';
import 'planner_shared.dart';

// =============================================================================
// SCREEN 2: CHOOSE MEAL / CATEGORY VIEW
// =============================================================================
class PlannerCategoryView extends GetView<MealPlannerController> {
  const PlannerCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final slot =
        (Get.arguments as Map?)?['slot'] as MealPlanSlot? ??
        MealPlanSlot.breakfast;
    final replace = (Get.arguments as Map?)?['replace'] as PlannedMeal?;

    return Obx(() => _PlannerScaffold(
      header: PlannerPageHeader(
        title:
            replace == null
                ? 'planner.add_slot'.trParams({'slot': slot.labelKey.tr})
                : 'planner.replace_meal'.tr,
        onClose:
            () => Get.until(
              (route) =>
                  route.settings.name == AppRoutes.mealPlanner || route.isFirst,
            ),
      ),
      child: controller.isLoadingRecommendations.value &&
              controller.adminRecommendations.isEmpty
          ? const PageSkeleton.plannerCategories()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search input preview
          _SearchPreview(
            hint: 'planner.search_meals'.tr,
            onTap:
                () => Get.toNamed(
                  AppRoutes.mealPlannerMeals,
                  arguments: {'slot': slot, 'replace': replace},
                ),
          ),
          const SizedBox(height: 14),

          // Filter tags horizontal scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final tag in const [
                  ('all', 'planner.all'),
                  ('popular', 'planner.popular'),
                  ('healthy', 'planner.healthy'),
                  ('quick', 'planner.quick'),
                  ('vegetarian', 'planner.vegetarian'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap:
                          () => Get.toNamed(
                            AppRoutes.mealPlannerMeals,
                            arguments: {
                              'slot': slot,
                              'replace': replace,
                              'filter': tag.$1,
                            },
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: context.appElevatedSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: context.appBorder.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Text(
                          tag.$2.tr,
                          style: TextStyle(
                            color: context.appText,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Title
          Text(
            'planner.choose_category'.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // 2-Column Category Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.categoriesFor(slot).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.12,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, index) {
              final category = controller.categoriesFor(slot)[index];
              return _CategoryCard(
                category: category,
                onTap:
                    () => Get.toNamed(
                      AppRoutes.mealPlannerMeals,
                      arguments: {
                        'slot': slot,
                        'replace': replace,
                        'category': category.name,
                        'categoryId': category.id,
                      },
                    ),
              );
            },
          ),

        ],
      ),
    ));
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final PlannerMealCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
          boxShadow: context.appTileShadow,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child:
                    category.imageUrl.isEmpty
                        ? Container(
                          color: context.appSoftGreen,
                          child: Center(
                            child: Icon(
                              Icons.restaurant_menu_rounded,
                              color: AppColors.primaryGreen,
                              size: 32,
                            ),
                          ),
                        )
                        : CachedNetworkImage(
                          imageUrl: category.imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (_, _) => Container(
                                color: context.appSoftGreen,
                                child: Center(
                                  child: Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 30,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (_, _, _) => Container(
                                color: context.appSoftGreen,
                                child: Center(
                                  child: Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 30,
                                  ),
                                ),
                              ),
                        ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SCREEN 3: SELECT MEAL LIST VIEW
// =============================================================================
class PlannerMealListView extends StatefulWidget {
  const PlannerMealListView({super.key});

  @override
  State<PlannerMealListView> createState() => _PlannerMealListViewState();
}

class _PlannerMealListViewState extends State<PlannerMealListView> {
  final controller = Get.find<MealPlannerController>();
  final search = TextEditingController();
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map? ?? const {};
    final initialFilter = args['filter'] as String?;
    if (initialFilter != null && initialFilter.isNotEmpty) {
      filter = initialFilter;
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map? ?? const {};
    final slot = args['slot'] as MealPlanSlot? ?? MealPlanSlot.breakfast;
    final category = '${args['category'] ?? ''}';
    final categoryId = int.tryParse('${args['categoryId'] ?? ''}');
    final replace = args['replace'] as PlannedMeal?;
    final query = search.text.trim().toLowerCase();

    List<PlannedMeal> mealsForCurrentFilters() =>
        controller.suggestionsFor(slot).where((meal) {
          if (categoryId != null && meal.categoryId != categoryId) {
            return false;
          }
          if (categoryId == null &&
              category.isNotEmpty &&
              meal.category.toLowerCase() != category.toLowerCase()) {
            return false;
          }
          if (query.isNotEmpty &&
              !plannerMealName(meal).toLowerCase().contains(query)) {
            return false;
          }
          return switch (filter) {
            'popular' => meal.tags.any(
              (tag) => tag.toLowerCase().contains('popular'),
            ),
            'healthy' => meal.tags.any(
              (tag) => tag.toLowerCase().contains('healthy'),
            ),
            'low' => meal.calories <= 400,
            'protein' => meal.proteinGrams >= 20,
            'quick' => meal.tags.any(
              (tag) => tag.toLowerCase().contains('quick'),
            ),
            'vegetarian' => meal.tags.any(
              (tag) => tag.toLowerCase().contains('vegetarian'),
            ),
            _ => true,
          };
        }).toList();

    return Obx(() {
      final meals = mealsForCurrentFilters();
      return _PlannerScaffold(
      header: PlannerPageHeader(
        title:
            replace == null
                ? 'planner.select_slot'.trParams({'slot': slot.labelKey.tr})
                : 'planner.replace_meal'.tr,
        onClose:
            () => Get.until(
              (route) =>
                  route.settings.name == AppRoutes.mealPlanner || route.isFirst,
            ),
      ),
      child: controller.isLoadingRecommendations.value &&
              controller.adminRecommendations.isEmpty
          ? const PageSkeleton.plannerMeals()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search TextField
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: context.appMutedText,
              ),
              suffixIcon:
                  search.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          search.clear();
                          setState(() {});
                        },
                      )
                      : null,
              hintText: 'planner.search_meals'.tr,
              filled: true,
              fillColor: context.appField,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter tags horizontal scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final item in const [
                  ('all', 'planner.all'),
                  ('low', 'planner.low_calorie'),
                  ('protein', 'planner.high_protein'),
                  ('quick', 'planner.quick'),
                  ('healthy', 'planner.healthy'),
                  ('popular', 'planner.popular'),
                  ('vegetarian', 'planner.vegetarian'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item.$2.tr),
                      selected: filter == item.$1,
                      onSelected: (_) => setState(() => filter = item.$1),
                      selectedColor: AppColors.primaryGreen,
                      backgroundColor: context.appElevatedSurface,
                      side: BorderSide(
                        color:
                            filter == item.$1
                                ? Colors.transparent
                                : context.appBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color:
                            filter == item.$1 ? Colors.white : context.appText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Meal List
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 54,
                      color: context.appMutedText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'planner.no_meals_found'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (filter != 'all' || search.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            filter = 'all';
                            search.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('planner.retry'.tr),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ...meals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap:
                      () => Get.toNamed(
                        AppRoutes.mealPlannerDetail,
                        arguments: {'meal': meal, 'replace': replace},
                      ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appElevatedSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.appBorder.withValues(alpha: 0.8),
                      ),
                      boxShadow: context.appTileShadow,
                    ),
                    child: Row(
                      children: [
                        // Left: Food Image Thumbnail
                        PlannerMealImage(
                          meal: meal,
                          width: 80,
                          height: 80,
                          radius: 14,
                        ),
                        const SizedBox(width: 14),

                        // Middle: Title, Tags, Macro info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plannerMealName(meal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.appText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (meal.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Wrap(
                                    spacing: 5,
                                    children:
                                        meal.tags
                                            .take(2)
                                            .map(
                                              (tag) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: context.appSoftGreen,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.primaryGreen,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                              Text(
                                '${meal.calories} ${'planner.kcal'.tr}  •  ${meal.proteinGrams.toStringAsFixed(0)}g ${'planner.protein'.tr}',
                                style: TextStyle(
                                  color: context.appMutedText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Right: Quick Add Button (+)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            final ok =
                                replace == null
                                    ? await controller.addMeal(meal)
                                    : await controller.replaceMeal(
                                      replace,
                                      meal,
                                    );
                            if (!ok) return;
                            Get.until(
                              (route) =>
                                  route.settings.name ==
                                      AppRoutes.mealPlanner ||
                                  route.isFirst,
                            );
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      );
    });
  }
}

// =============================================================================
// SCREEN 4: MEAL DETAIL VIEW
// =============================================================================
class PlannerMealDetailView extends StatefulWidget {
  const PlannerMealDetailView({super.key});

  @override
  State<PlannerMealDetailView> createState() => _PlannerMealDetailViewState();
}

class _PlannerMealDetailViewState extends State<PlannerMealDetailView> {
  final controller = Get.find<MealPlannerController>();
  double servings = 1;
  bool favorite = false;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map? ?? const {};
    final meal = args['meal'] as PlannedMeal;
    final replace = args['replace'] as PlannedMeal?;

    return Obx(() => _PlannerScaffold(
      bottom: Obx(
        () => PlannerPrimaryButton(
          label:
              controller.isSaving.value
                  ? 'planner.saving'.tr
                  : (replace == null
                      ? 'planner.add_to_planner'.tr
                      : 'planner.replace_meal'.tr),
          onPressed:
              controller.isSaving.value
                  ? null
                  : () async {
                    final ok =
                        replace == null
                            ? await controller.addMeal(meal, servings: servings)
                            : await controller.replaceMeal(
                              replace,
                              meal,
                              servings: servings,
                            );
                    if (!ok) return;
                    Get.until(
                      (route) =>
                          route.settings.name == AppRoutes.mealPlanner ||
                          route.isFirst,
                    );
                  },
        ),
      ),
      header: const SizedBox.shrink(),
      child: controller.isLoadingRecommendations.value &&
              controller.adminRecommendations.isEmpty
          ? const PageSkeleton.plannerDetail()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Food Image with Floating Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
            child: SizedBox(
              width: double.infinity,
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlannerMealImage(
                      meal: meal,
                      width: double.infinity,
                      height: 280,
                      radius: 22,
                    ),
                    Positioned(
                      top: 16,
                      left: 18,
                      child: _HeroCircleButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: Get.back<void>,
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 68,
                      child: _HeroCircleButton(
                        icon:
                            favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                        color:
                            favorite ? Colors.redAccent : AppColors.primaryGreen,
                        onTap: () => setState(() => favorite = !favorite),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 18,
                      child: _HeroCircleButton(
                        icon: Icons.ios_share_rounded,
                        onTap:
                            () => SharePlus.instance.share(
                              ShareParams(text: plannerMealName(meal)),
                            ),
                      ),
                    ),
                    if (meal.tags.isNotEmpty)
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 14,
                        child: Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children:
                              meal.tags.take(3).map((tag) => _HeroTag(tag)).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Meal Name
          Text(
            plannerMealName(meal),
            style: TextStyle(
              color: context.appText,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              if (meal.cookingTimeMinutes != null) ...[
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: context.appMutedText,
                ),
                const SizedBox(width: 5),
                Text(
                  '${meal.cookingTimeMinutes} min',
                  style: TextStyle(color: context.appMutedText, fontSize: 12.5),
                ),
                const SizedBox(width: 16),
              ],
              Icon(
                Icons.restaurant_rounded,
                size: 18,
                color: context.appMutedText,
              ),
              const SizedBox(width: 5),
              Text(
                '${servings.toStringAsFixed(servings == servings.roundToDouble() ? 0 : 1)} ${'planner.serving'.tr}',
                style: TextStyle(color: context.appMutedText, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Macro Nutrition Cards Row
          Row(
            children: [
              _NutrientCard(
                value: '${(meal.calories * servings).round()}',
                label: 'planner.kcal'.tr,
                color: const Color(0xFFD97706),
                icon: Icons.local_fire_department_rounded,
              ),
              const SizedBox(width: 5),
              _NutrientCard(
                value: '${(meal.proteinGrams * servings).toStringAsFixed(0)}g',
                label: 'planner.protein'.tr,
                color: const Color(0xFF2563EB),
                icon: Icons.fitness_center_rounded,
              ),
              const SizedBox(width: 5),
              _NutrientCard(
                value: '${(meal.carbsGrams * servings).toStringAsFixed(0)}g',
                label: 'planner.carbs'.tr,
                color: AppColors.primaryGreen,
                icon: Icons.grain_rounded,
              ),
              const SizedBox(width: 5),
              _NutrientCard(
                value: '${(meal.fatGrams * servings).toStringAsFixed(0)}g',
                label: 'planner.fat'.tr,
                color: const Color(0xFFE11D48),
                icon: Icons.water_drop_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),

          _SectionTitle('planner.servings'.tr),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.appElevatedSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed:
                      servings > .5
                          ? () => setState(() => servings -= .5)
                          : null,
                  icon: const Icon(Icons.remove_rounded),
                  color: AppColors.primaryGreen,
                ),
                Expanded(
                  child: Text(
                    servings.toStringAsFixed(
                      servings == servings.roundToDouble() ? 0 : 1,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: () => setState(() => servings += .5),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          _SectionTitle('planner.description'.tr),
          const SizedBox(height: 8),
          Text(
            meal.description.isEmpty
                ? 'planner.default_description'.tr
                : meal.description.tr,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          // Ingredients Checklist
          _SectionTitle('planner.ingredients'.tr),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appElevatedSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.appBorder.withValues(alpha: 0.8),
              ),
            ),
            child: Column(
              children: [
                if (meal.ingredients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'planner.ingredient_whole_grain_bread'.tr,
                      style: TextStyle(color: context.appMutedText),
                    ),
                  )
                else
                  ...meal.ingredients.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.tr,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Cooking Instructions (if any)
          if (meal.instructions.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionTitle('planner.instructions'.tr),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.appElevatedSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: context.appBorder.withValues(alpha: 0.8),
                ),
              ),
              child: Column(
                children:
                    meal.instructions.indexed.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: context.appSoftGreen,
                              child: Text(
                                '${entry.$1 + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.$2,
                                style: TextStyle(
                                  color: context.appText,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    ));
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.primaryGreen,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: context.appElevatedSurface.withValues(alpha: 0.94),
    shape: const CircleBorder(),
    elevation: 3,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: color, size: 23),
      ),
    ),
  );
}

class _HeroTag extends StatelessWidget {
  const _HeroTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.56),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
          boxShadow: context.appTileShadow,
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: context.appMutedText,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SCREEN 7: WEEKLY PLANNER VIEW
// =============================================================================
class PlannerWeeklyView extends GetView<MealPlannerController> {
  const PlannerWeeklyView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    return _PlannerScaffold(
      header: PlannerPageHeader(
        title: 'planner.title'.tr,
        trailing: IconButton(
          icon: const Icon(
            Icons.shopping_basket_outlined,
            color: AppColors.primaryGreen,
          ),
          onPressed: () => Get.toNamed(AppRoutes.mealPlannerGrocery),
        ),
      ),
      child: controller.isLoading.value && controller.plans.isEmpty
          ? const PageSkeleton.plannerWeek()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlannerFlowWeekCard(controller: controller),
          const SizedBox(height: 16),

          // Weekly Progress Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CircularProgressIndicator(
                    value: controller.weeklyProgress.clamp(0, 1),
                    strokeWidth: 6.5,
                    backgroundColor: context.appBorder,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'planner.weekly_progress'.tr,
                        style: TextStyle(
                          color: context.appText,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'planner.meals_planned'.trParams({
                          'count': '${controller.weeklyMealCount}',
                          'total': '28',
                        }),
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(controller.weeklyProgress * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 7-Day Planned Meal Cards
          Text(
            'planner.seven_days'.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          ...controller.weekDays.indexed.map((entry) {
            final dayIndex = entry.$1;
            final date = entry.$2;
            final meals = controller.mealsFor(date);
            final isSelected = dayIndex == controller.selectedDayIndex.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  controller.selectDay(dayIndex);
                  Get.back<void>();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.appElevatedSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.primaryGreen.withValues(alpha: 0.8)
                              : context.appBorder.withValues(alpha: 0.8),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: context.appTileShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Day name + Meal count chip + Chevron
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, d MMM').format(date),
                              style: TextStyle(
                                color: context.appText,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  meals.length == 4
                                      ? AppColors.primaryGreen
                                      : context.appSoftGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${meals.length}/4 ${'planner.meals'.tr}',
                              style: TextStyle(
                                color:
                                    meals.length == 4
                                        ? Colors.white
                                        : AppColors.primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.appMutedText,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4 Meal Slots Previews Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                            MealPlanSlot.values.map((slot) {
                              final slotMeal = meals.firstWhereOrNull(
                                (m) => m.slot == slot,
                              );
                              final slotTheme = PlannerSlotTheme.of(slot);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: Column(
                                    children: [
                                      // Slot thumbnail or empty container
                                      if (slotMeal != null)
                                        PlannerMealImage(
                                          meal: slotMeal,
                                          height: 52,
                                          radius: 12,
                                        )
                                      else
                                        Container(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color:
                                                context.appIsDark
                                                    ? slotTheme.soft.withValues(
                                                      alpha: 0.1,
                                                    )
                                                    : slotTheme.soft.withValues(
                                                      alpha: 0.4,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: context.appBorder
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              slotTheme.icon,
                                              size: 20,
                                              color: slotTheme.accent
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        slot.labelKey.tr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: context.appMutedText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  });
}

// =============================================================================
// SCREEN 8: GENERATE GROCERY LIST VIEW
// =============================================================================
class PlannerGroceryView extends StatefulWidget {
  const PlannerGroceryView({super.key});

  @override
  State<PlannerGroceryView> createState() => _PlannerGroceryViewState();
}

class _PlannerGroceryViewState extends State<PlannerGroceryView> {
  final controller = Get.find<MealPlannerController>();
  final checked = <String>{};

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final grouped = <String, List<GroceryItem>>{};
      for (final item in controller.groceryItems) {
        (grouped[item.category] ??= []).add(item);
      }
      final totalItems = controller.groceryItems.length;
      final checkedCount = checked.length;

      return _PlannerScaffold(
      header: PlannerPageHeader(
        title: 'planner.grocery_list'.tr,
        trailing:
            totalItems > 0
                ? TextButton(
                  onPressed: () {
                    setState(() {
                      if (checked.length == totalItems) {
                        checked.clear();
                      } else {
                        checked.addAll(
                          controller.groceryItems.map((i) => i.key),
                        );
                      }
                    });
                  },
                  child: Text(
                    checked.length == totalItems
                        ? 'planner.cancel'.tr
                        : 'planner.all'.tr,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                : null,
      ),
      bottom:
          totalItems == 0
              ? null
              : PlannerPrimaryButton(
                label: 'planner.share_list'.tr,
                icon: Icons.share_outlined,
                onPressed: () async {
                  final lines = controller.groceryItems
                      .map(
                        (i) =>
                            '${checked.contains(i.key) ? '☑' : '☐'} ${i.name.tr}${i.quantityLabel.isEmpty ? '' : ' — ${i.quantityLabel}'}',
                      )
                      .join('\n');
                  await SharePlus.instance.share(
                    ShareParams(
                      text:
                          '${'planner.grocery_list'.tr}\n${_range(controller.weekStart, controller.weekDays.last)}\n\n$lines',
                    ),
                  );
                },
              ),
      child:
          controller.isLoading.value && controller.plans.isEmpty
              ? const PageSkeleton.plannerGrocery()
              : grouped.isEmpty
              ? _EmptyGrocery()
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress chip / summary banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSoftGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$checkedCount / $totalItems ${'planner.meals_planned_short'.tr}',
                            style: TextStyle(
                              color: context.appText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (checkedCount > 0)
                          InkWell(
                            onTap: () => setState(checked.clear),
                            child: Text(
                              'planner.remove'.tr,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Categorized checklist groups
                  ...grouped.entries.map((group) {
                    final categoryIcon = _iconForGroceryCategory(group.key);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Header
                          Row(
                            children: [
                              Icon(
                                categoryIcon,
                                size: 18,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                group.key.tr,
                                style: TextStyle(
                                  color: context.appText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.appElevatedSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.appBorder),
                                ),
                                child: Text(
                                  '${group.value.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: context.appMutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Items in this category
                          ...group.value.map((item) {
                            final isItemChecked = checked.contains(item.key);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.appElevatedSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: context.appBorder.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isItemChecked,
                                  activeColor: AppColors.primaryGreen,
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  onChanged:
                                      (value) => setState(
                                        () =>
                                            value == true
                                                ? checked.add(item.key)
                                                : checked.remove(item.key),
                                      ),
                                  title: Text(
                                    item.name.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color:
                                          isItemChecked
                                              ? context.appMutedText
                                              : context.appText,
                                      decoration:
                                          isItemChecked
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                  secondary:
                                      item.quantityLabel.isEmpty
                                          ? null
                                          : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.appSoftGreen,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.quantityLabel,
                                              style: const TextStyle(
                                                color: AppColors.primaryGreen,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      );
    });
  }

  IconData _iconForGroceryCategory(String key) {
    if (key.contains('produce')) return Icons.eco_rounded;
    if (key.contains('protein')) return Icons.egg_rounded;
    if (key.contains('grain')) return Icons.grain_rounded;
    if (key.contains('dairy')) return Icons.local_drink_rounded;
    return Icons.shopping_basket_rounded;
  }
}

// =============================================================================
// SCAFFOLD & REUSABLE COMPONENTS
// =============================================================================
class _PlannerScaffold extends StatelessWidget {
  const _PlannerScaffold({
    required this.header,
    required this.child,
    this.bottom,
  });

  final Widget header;
  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    body: AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontalFor(context),
                12,
                AppSpacing.pageHorizontalFor(context),
                0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: header,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontalFor(context),
                  14,
                  AppSpacing.pageHorizontalFor(context),
                  bottom == null ? 28 : 100,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar:
        bottom == null
            ? null
            : SafeArea(
              minimum: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontalFor(context),
                8,
                AppSpacing.pageHorizontalFor(context),
                12,
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: bottom,
                ),
              ),
            ),
  );
}

class _SearchPreview extends StatelessWidget {
  const _SearchPreview({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.appField,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: context.appMutedText),
          const SizedBox(width: 12),
          Text(
            hint,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: TextStyle(
      color: context.appText,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _EmptyGrocery extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 80),
    child: Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              size: 52,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'planner.no_meals'.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'planner.empty_grocery_list'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMutedText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.add_rounded),
            label: Text('planner.add_first_meal'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlannerFlowWeekCard extends StatelessWidget {
  const _PlannerFlowWeekCard({required this.controller});

  final MealPlannerController controller;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
      boxShadow: context.appTileShadow,
    ),
    child: Column(
      children: [
        Row(
          children: [
            _flowWeekArrow(context, Icons.chevron_left_rounded, -1),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.weekOffset.value == 0
                        ? 'planner.this_week'.tr
                        : 'planner.selected_week'.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _range(controller.weekStart, controller.weekDays.last),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _flowWeekArrow(context, Icons.chevron_right_rounded, 1),
          ],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: context.appBorder.withValues(alpha: 0.65)),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.weekDays.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (_, index) {
              final date = controller.weekDays[index];
              final selected = index == controller.selectedDayIndex.value;
              final hasMeals = controller.mealsFor(date).isNotEmpty;
              return InkWell(
                onTap: () => controller.selectDay(index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 55,
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? AppColors.primaryGreen
                            : context.appBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          selected
                              ? AppColors.primaryGreen
                              : context.appBorder.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          color: selected ? Colors.white : context.appMutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: selected ? Colors.white : context.appText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? Colors.white
                                  : (hasMeals
                                      ? AppColors.primaryGreen
                                      : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _flowWeekArrow(BuildContext context, IconData icon, int amount) =>
      IconButton(
        onPressed: () => controller.changeWeek(amount),
        icon: Icon(icon),
        color: context.appText,
        style: IconButton.styleFrom(
          backgroundColor: context.appBackground,
          shape: const CircleBorder(),
        ),
      );
}

String _range(DateTime start, DateTime end) =>
    '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
