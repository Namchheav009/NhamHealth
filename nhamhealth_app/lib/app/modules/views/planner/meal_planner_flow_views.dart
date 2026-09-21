import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_nutrient_theme.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../models/planner/meal_plan.dart';
import '../wellness/widgets/ingredient_avatar.dart';
import 'planner_shared.dart';

Map<dynamic, dynamic> _plannerRouteArguments() {
  final arguments = Get.arguments;
  return arguments is Map ? arguments : const {};
}

T? _plannerArgument<T>(Map<dynamic, dynamic> arguments, String key) {
  final value = arguments[key];
  return value is T ? value : null;
}

// =============================================================================
// SCREEN 2: CHOOSE MEAL / CATEGORY VIEW
// =============================================================================
class PlannerCategoryView extends StatefulWidget {
  const PlannerCategoryView({super.key});

  @override
  State<PlannerCategoryView> createState() => _PlannerCategoryViewState();
}

class _PlannerCategoryViewState extends State<PlannerCategoryView> {
  final controller = Get.find<MealPlannerController>();

  @override
  void initState() {
    super.initState();
    if (controller.adminRecommendations.isEmpty &&
        !controller.isLoadingRecommendations.value) {
      controller.loadRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = _plannerRouteArguments();
    final slot =
        _plannerArgument<MealPlanSlot>(arguments, 'slot') ??
        MealPlanSlot.breakfast;
    final replace = _plannerArgument<PlannedMeal>(arguments, 'replace');

    return Obx(
      () => _PlannerScaffold(
        header: PlannerPageHeader(
          title:
              replace == null
                  ? 'planner.add_slot'.trParams({'slot': slot.labelKey.tr})
                  : 'planner.replace_meal'.tr,
          subtitle: DateFormat('EEE, d MMM').format(controller.selectedDate),
          onClose:
              () => Get.until(
                (route) =>
                    route.settings.name == AppRoutes.mealPlanner ||
                    route.isFirst,
              ),
        ),
        child: LoadingContentTransition(
          isLoading: controller.isLoadingRecommendations.value,
          loading: const PageSkeleton.plannerCategories(),
          content: Column(
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
                                height: 1.3,
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
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // Categories are optional; always leave a path to the full meal list.
              if (controller.categoriesFor(slot).isEmpty)
                OutlinedButton.icon(
                  onPressed:
                      () => Get.toNamed(
                        AppRoutes.mealPlannerMeals,
                        arguments: {'slot': slot, 'replace': replace},
                      ),
                  icon: const Icon(Icons.restaurant_menu_rounded),
                  label: Text('planner.browse_all_meals'.tr),
                )
              else
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
        ),
      ),
    );
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
                          imageUrl: plannerImageUrl(category.imageUrl),
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
                height: 1.35,
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
  String sortMode = 'goal';
  int? selectedCategoryId;
  late MealPlanSlot selectedSlot;

  @override
  void initState() {
    super.initState();
    final args = _plannerRouteArguments();
    selectedSlot =
        _plannerArgument<MealPlanSlot>(args, 'slot') ?? MealPlanSlot.breakfast;
    final initialFilter = _plannerArgument<String>(args, 'filter');
    if (initialFilter != null && initialFilter.isNotEmpty) {
      filter = initialFilter;
    }
    selectedCategoryId = int.tryParse('${args['categoryId'] ?? ''}');
    if (controller.adminRecommendations.isEmpty &&
        !controller.isLoadingRecommendations.value) {
      controller.loadRecommendations();
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = _plannerRouteArguments();
    final slot = selectedSlot;
    final replace = _plannerArgument<PlannedMeal>(args, 'replace');
    final query = search.text.trim().toLowerCase();

    List<PlannedMeal> mealsForCurrentFilters() {
      final meals =
          controller.availableMealsFor(slot).where((meal) {
            if (selectedCategoryId != null &&
                meal.categoryId != selectedCategoryId &&
                !meal.categoryIds.contains(selectedCategoryId)) {
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
      switch (sortMode) {
        case 'goal':
          meals.sort((a, b) {
            double score(PlannedMeal meal) {
              final density =
                  meal.calories > 0
                      ? meal.proteinGrams * 100 / meal.calories
                      : 0.0;
              return density * 7 -
                  (meal.calories - 550).clamp(0, double.infinity) * 0.12;
            }

            return score(b).compareTo(score(a));
          });
        case 'calories':
          meals.sort((a, b) => a.calories.compareTo(b.calories));
        case 'protein':
          meals.sort((a, b) => b.proteinGrams.compareTo(a.proteinGrams));
        case 'quickest':
          meals.sort(
            (a, b) => (a.cookingTimeMinutes ?? 999).compareTo(
              b.cookingTimeMinutes ?? 999,
            ),
          );
        default:
          meals.sort((a, b) {
            final aPopular = a.tags.any(
              (tag) => tag.toLowerCase().contains('popular'),
            );
            final bPopular = b.tags.any(
              (tag) => tag.toLowerCase().contains('popular'),
            );
            if (aPopular != bPopular) return aPopular ? -1 : 1;
            return a.name.compareTo(b.name);
          });
      }
      return meals;
    }

    return Obx(() {
      final meals = mealsForCurrentFilters();
      return _PlannerScaffold(
        header: PlannerPageHeader(
          title:
              replace == null
                  ? 'planner.select_meal'.tr
                  : 'planner.replace_meal'.tr,
          subtitle: DateFormat('EEE, d MMM').format(controller.selectedDate),
          onClose:
              () => Get.until(
                (route) =>
                    route.settings.name == AppRoutes.mealPlanner ||
                    route.isFirst,
              ),
        ),
        child: LoadingContentTransition(
          isLoading: controller.isLoadingRecommendations.value,
          loading: const PageSkeleton.plannerMeals(),
          content: Column(
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
                            tooltip: 'common.clear_all'.tr,
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            style: IconButton.styleFrom(
                              foregroundColor: context.appMutedText,
                              hoverColor: context.appBorder.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            onPressed: () {
                              search.clear();
                              setState(() {});
                            },
                          )
                          : IconButton(
                            tooltip: 'planner.filter_nutrition'.tr,
                            icon: Badge(
                              isLabelVisible: filter != 'all',
                              label: const Text('1'),
                              child: Icon(
                                Icons.tune_rounded,
                                color:
                                    filter != 'all'
                                        ? AppColors.primaryGreen
                                        : context.appMutedText,
                              ),
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  filter != 'all'
                                      ? context.appSoftGreen
                                      : Colors.transparent,
                              hoverColor: AppColors.primaryGreen.withValues(
                                alpha: 0.14,
                              ),
                              focusColor: AppColors.primaryGreen.withValues(
                                alpha: 0.18,
                              ),
                            ),
                            onPressed: () => _showPlannerFilters(context),
                          ),
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

              // Meal-time selector
              SingleChildScrollView(
                key: const ValueKey<String>('planner-slot-filters'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final mealSlot in MealPlanSlot.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(
                            mealSlot.icon,
                            size: 17,
                            color:
                                selectedSlot == mealSlot
                                    ? Colors.white
                                    : PlannerSlotTheme.of(mealSlot).accent,
                          ),
                          label: Text(mealSlot.labelKey.tr),
                          selected: selectedSlot == mealSlot,
                          onSelected:
                              (_) => setState(() {
                                selectedSlot = mealSlot;
                                selectedCategoryId = null;
                              }),
                          selectedColor: AppColors.primaryGreen,
                          backgroundColor: context.appElevatedSurface,
                          side: BorderSide(
                            color:
                                selectedSlot == mealSlot
                                    ? Colors.transparent
                                    : context.appBorder,
                          ),
                          labelStyle: TextStyle(
                            color:
                                selectedSlot == mealSlot
                                    ? Colors.white
                                    : context.appText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Category chips filter
              Builder(
                builder: (context) {
                  final categories = controller.categoriesFor(selectedSlot);
                  if (categories.isEmpty) return const SizedBox.shrink();
                  return SingleChildScrollView(
                    key: const ValueKey<String>('planner-category-filters'),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text('planner.all'.tr),
                            selected: selectedCategoryId == null,
                            onSelected:
                                (_) =>
                                    setState(() => selectedCategoryId = null),
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: context.appElevatedSurface,
                            side: BorderSide(
                              color:
                                  selectedCategoryId == null
                                      ? Colors.transparent
                                      : context.appBorder,
                            ),
                            labelStyle: TextStyle(
                              color:
                                  selectedCategoryId == null
                                      ? Colors.white
                                      : context.appText,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        for (final category in categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text(category.name),
                              selected: selectedCategoryId == category.id,
                              onSelected:
                                  (_) => setState(
                                    () => selectedCategoryId = category.id,
                                  ),
                              selectedColor: AppColors.primaryGreen,
                              backgroundColor: context.appElevatedSurface,
                              side: BorderSide(
                                color:
                                    selectedCategoryId == category.id
                                        ? Colors.transparent
                                        : context.appBorder,
                              ),
                              labelStyle: TextStyle(
                                color:
                                    selectedCategoryId == category.id
                                        ? Colors.white
                                        : context.appText,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${'planner.recommended_meals'.tr}  ·  ${meals.length}',
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0F62FE,
                            ).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(
                                0xFF0F62FE,
                              ).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 10,
                                color: Color(0xFF0F62FE),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'planner.goal_lose_weight'.tr,
                                style: const TextStyle(
                                  color: Color(0xFF0F62FE),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'planner.sort_by'.tr,
                    initialValue: sortMode,
                    onSelected: (value) => setState(() => sortMode = value),
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder:
                        (_) =>
                            [
                                  (
                                    'goal',
                                    'planner.sort_goal_match',
                                    Icons.track_changes_rounded,
                                  ),
                                  (
                                    'popular',
                                    'planner.popular',
                                    Icons.trending_up_rounded,
                                  ),
                                  (
                                    'calories',
                                    'planner.sort_lowest_calories',
                                    Icons.local_fire_department_outlined,
                                  ),
                                  (
                                    'protein',
                                    'planner.sort_highest_protein',
                                    Icons.fitness_center_rounded,
                                  ),
                                  (
                                    'quickest',
                                    'planner.sort_quickest',
                                    Icons.schedule_rounded,
                                  ),
                                ]
                                .map(
                                  (item) => PopupMenuItem<String>(
                                    value: item.$1,
                                    child: Row(
                                      children: [
                                        Icon(
                                          item.$3,
                                          size: 18,
                                          color:
                                              sortMode == item.$1
                                                  ? AppColors.primaryGreen
                                                  : context.appMutedText,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          item.$2.tr,
                                          style: TextStyle(
                                            fontWeight:
                                                sortMode == item.$1
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                            color:
                                                sortMode == item.$1
                                                    ? AppColors.primaryGreen
                                                    : context.appText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: context.appSoftGreen,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${'planner.sort_by'.tr}: ${_plannerSortLabel(sortMode)}',
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryGreen,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                        if (filter != 'all' ||
                            selectedCategoryId != null ||
                            search.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                filter = 'all';
                                selectedCategoryId = null;
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
                      hoverColor: AppColors.primaryGreen.withValues(
                        alpha: 0.045,
                      ),
                      splashColor: AppColors.primaryGreen.withValues(
                        alpha: 0.09,
                      ),
                      onTap:
                          () => Get.toNamed(
                            AppRoutes.mealPlannerDetail,
                            arguments: {
                              'meal': meal,
                              'replace': replace,
                              'slot': selectedSlot,
                              'isAlreadyPlanned': false,
                            },
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
                              width: 96,
                              height: 96,
                              radius: 17,
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
                                      height: 1.35,
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
                                                      color:
                                                          context.appSoftGreen,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      tag,
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors
                                                                .primaryGreen,
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  Text(
                                    '🔥 ${meal.calories} ${'planner.kcal'.tr}   🏋 ${meal.proteinGrams.toStringAsFixed(0)}g ${'planner.protein'.tr}${meal.cookingTimeMinutes == null ? '' : '   ◷ ${meal.cookingTimeMinutes} ${'planner.minutes_short'.tr}'}',
                                    maxLines: 2,
                                    style: TextStyle(
                                      color: context.appMutedText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Right: Quick Add Button (+)
                            IconButton(
                              tooltip: 'planner.quick_add'.tr,
                              onPressed: () async {
                                final targetMeal = meal.copyWith(
                                  slot: selectedSlot,
                                );
                                final ok =
                                    replace == null
                                        ? await controller.addMeal(
                                          targetMeal,
                                          targetSlot: selectedSlot,
                                        )
                                        : await controller.replaceMeal(
                                          replace,
                                          targetMeal,
                                        );
                                if (!ok) return;
                                Get.until(
                                  (route) =>
                                      route.settings.name ==
                                          AppRoutes.mealPlanner ||
                                      route.isFirst,
                                );
                                AppAlert.toast(
                                  message:
                                      replace == null
                                          ? 'planner.meal_added_one_serving'.tr
                                          : 'planner.meal_replaced'.tr,
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 24),
                              style: ButtonStyle(
                                minimumSize: const WidgetStatePropertyAll(
                                  Size.square(48),
                                ),
                                foregroundColor: const WidgetStatePropertyAll(
                                  Colors.white,
                                ),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                      (states) =>
                                          states.contains(WidgetState.hovered)
                                              ? const Color(0xFF008A46)
                                              : AppColors.primaryGreen,
                                    ),
                                overlayColor: WidgetStatePropertyAll(
                                  Colors.white.withValues(alpha: 0.14),
                                ),
                                shape: const WidgetStatePropertyAll(
                                  CircleBorder(),
                                ),
                                elevation: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.hovered)
                                          ? 5
                                          : 1,
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
        ),
      );
    });
  }

  void _showPlannerFilters(BuildContext context) {
    var draftFilter = filter;
    Get.bottomSheet<void>(
      StatefulBuilder(
        builder:
            (sheetContext, setSheetState) => SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
                ),
                decoration: BoxDecoration(
                  color: sheetContext.appElevatedSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: sheetContext.appBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'meals.filters'.tr,
                              style: TextStyle(
                                color: sheetContext.appText,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                () => setSheetState(() => draftFilter = 'all'),
                            child: Text('common.clear_all'.tr),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'planner.filter_nutrition'.tr,
                        style: TextStyle(
                          color: sheetContext.appText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in const [
                            ('all', 'planner.all', Icons.tune_rounded),
                            ('low', 'planner.low_calorie', Icons.eco_rounded),
                            (
                              'protein',
                              'planner.high_protein',
                              Icons.fitness_center_rounded,
                            ),
                            ('quick', 'planner.quick', Icons.bolt_rounded),
                            (
                              'healthy',
                              'planner.healthy',
                              Icons.favorite_outline_rounded,
                            ),
                            (
                              'vegetarian',
                              'planner.vegetarian',
                              Icons.spa_outlined,
                            ),
                          ])
                            ChoiceChip(
                              showCheckmark: false,
                              avatar: Icon(item.$3, size: 17),
                              label: Text(item.$2.tr),
                              selected: draftFilter == item.$1,
                              onSelected:
                                  (_) => setSheetState(
                                    () => draftFilter = item.$1,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() => filter = draftFilter);
                            Get.back<void>();
                          },
                          child: Text('common.done'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

String _plannerSortLabel(String value) => switch (value) {
  'goal' => 'planner.sort_goal_match'.tr,
  'calories' => 'planner.sort_lowest_calories'.tr,
  'protein' => 'planner.sort_highest_protein'.tr,
  'quickest' => 'planner.sort_quickest'.tr,
  _ => 'planner.popular'.tr,
};

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
  bool _servingsInitialized = false;

  @override
  Widget build(BuildContext context) {
    final args = _plannerRouteArguments();
    final PlannedMeal resolvedMeal;
    final rawMeal = _plannerArgument<PlannedMeal>(args, 'meal');
    if (rawMeal != null) {
      resolvedMeal = rawMeal;
    } else {
      final mealId = int.tryParse('${args['mealId'] ?? args['id'] ?? ''}');
      final found =
          mealId != null
              ? controller.adminRecommendations.firstWhereOrNull(
                (m) => m.id == mealId || m.planId == mealId,
              )
              : null;
      if (found == null) {
        return _PlannerScaffold(
          header: PlannerPageHeader(
            title: 'planner.details'.tr,
            onClose: () => Get.back(),
          ),
          child: const PageSkeleton.plannerDetail(),
        );
      }
      resolvedMeal = found;
    }
    final meal = resolvedMeal;
    if (!_servingsInitialized) {
      if (meal.servings > 0) {
        servings = meal.servings;
      }
      _servingsInitialized = true;
    }

    final replace = _plannerArgument<PlannedMeal>(args, 'replace');
    final isAlreadyPlanned =
        _plannerArgument<bool>(args, 'isAlreadyPlanned') ?? false;
    final targetSlot =
        _plannerArgument<MealPlanSlot>(args, 'slot') ?? meal.slot;
    final bool servingsChanged =
        isAlreadyPlanned && (servings != meal.servings);

    String buttonLabel() {
      if (controller.isSaving.value) return 'planner.saving'.tr;
      if (isAlreadyPlanned) {
        return servingsChanged
            ? 'planner.update_servings'.tr
            : 'planner.currently_planned'.tr;
      }
      if (replace != null) return 'planner.replace_meal'.tr;
      return 'planner.add_to_planner'.tr;
    }

    Future<void> onButtonPressed() async {
      if (controller.isSaving.value) return;
      if (isAlreadyPlanned) {
        if (servingsChanged) {
          await controller.changeServing(meal, servings);
          Get.back();
          AppAlert.toast(message: 'planner.servings_updated'.tr);
        } else {
          Get.back();
        }
        return;
      }

      if (replace != null) {
        final targetMeal = meal.copyWith(slot: replace.slot);
        final ok = await controller.replaceMeal(
          replace,
          targetMeal,
          servings: servings,
        );
        if (!ok) return;
        Get.until(
          (route) =>
              route.settings.name == AppRoutes.mealPlanner || route.isFirst,
        );
        AppAlert.toast(message: 'planner.meal_replaced'.tr);
        return;
      }

      final targetMeal = meal.copyWith(slot: targetSlot);
      final ok = await controller.addMeal(
        targetMeal,
        servings: servings,
        targetSlot: targetSlot,
      );
      if (!ok) return;
      Get.until(
        (route) =>
            route.settings.name == AppRoutes.mealPlanner || route.isFirst,
      );
      AppAlert.toast(message: 'planner.meal_added'.tr);
    }

    return Obx(
      () => _PlannerScaffold(
        bottom: Obx(
          () => PlannerPrimaryButton(
            label: buttonLabel(),
            onPressed: controller.isSaving.value ? null : onButtonPressed,
          ),
        ),
        header: const SizedBox.shrink(),
        child: LoadingContentTransition(
          isLoading:
              controller.isLoadingRecommendations.value &&
              controller.adminRecommendations.isEmpty,
          loading: const PageSkeleton.plannerDetail(),
          content: Column(
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
                                  meal.tags
                                      .take(3)
                                      .map((tag) => _HeroTag(tag))
                                      .toList(),
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
                  height: 1.35,
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
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12.5,
                      ),
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
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 12.5,
                    ),
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
                    color: AppNutrientTheme.caloriesColor,
                    icon: AppNutrientTheme.caloriesIcon,
                  ),
                  const SizedBox(width: 5),
                  _NutrientCard(
                    value:
                        '${(meal.proteinGrams * servings).toStringAsFixed(0)}g',
                    label: 'planner.protein'.tr,
                    color: AppNutrientTheme.proteinColor,
                    icon: AppNutrientTheme.proteinIcon,
                  ),
                  const SizedBox(width: 5),
                  _NutrientCard(
                    value:
                        '${(meal.carbsGrams * servings).toStringAsFixed(0)}g',
                    label: 'planner.carbs'.tr,
                    color: AppNutrientTheme.carbsColor,
                    icon: AppNutrientTheme.carbsIcon,
                  ),
                  const SizedBox(width: 5),
                  _NutrientCard(
                    value: '${(meal.fatGrams * servings).toStringAsFixed(0)}g',
                    label: 'planner.fat'.tr,
                    color: AppNutrientTheme.fatColor,
                    icon: AppNutrientTheme.fatIcon,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _SectionTitle('planner.servings'.tr),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                                    height: 1.35,
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
        ),
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

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
        child: Icon(icon, color: AppColors.primaryGreen, size: 23),
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
                height: 1.25,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'planner.auto_fill'.tr,
              icon: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primaryGreen,
              ),
              onPressed: () => showAutoFillConfirmDialog(context, controller),
            ),
            IconButton(
              tooltip: 'planner.grocery_list'.tr,
              icon: const Icon(
                Icons.shopping_basket_outlined,
                color: AppColors.primaryGreen,
              ),
              onPressed: () => Get.toNamed(AppRoutes.mealPlannerGrocery),
            ),
          ],
        ),
      ),
      child: LoadingContentTransition(
        isLoading:
            !controller.hasLoadedOnce.value || controller.isLoading.value,
        loading: const PageSkeleton.plannerWeek(),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlannerFlowWeekCard(controller: controller),
            const SizedBox(height: 16),

            // Weekly Progress & Nutrition Dashboard Card
            _weeklyProgressDashboard(context, controller),
            const SizedBox(height: 18),

            // Planned Meal Cards Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.planDaysCount.value == 7
                        ? 'planner.seven_days'.tr
                        : 'planner.days_plan'.trParams({
                          'days': '${controller.planDaysCount.value}',
                        }),
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'planner.tap_to_view_day'.tr,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...controller.weekDays.indexed.map((entry) {
              final dayIndex = entry.$1;
              final date = entry.$2;
              final meals = controller.mealsFor(date);
              final isSelected = dayIndex == controller.selectedDayIndex.value;
              final now = DateTime.now();
              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              final dayCalories = meals.fold<int>(
                0,
                (sum, m) => sum + (m.calories * m.servings).round(),
              );
              final dayProtein = meals.fold<double>(
                0.0,
                (sum, m) => sum + (m.proteinGrams * m.servings),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    controller.selectDay(dayIndex);
                    Get.back<void>();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appElevatedSurface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primaryGreen.withValues(alpha: 0.85)
                                : isToday
                                ? AppColors.primaryGreen.withValues(alpha: 0.45)
                                : context.appBorder.withValues(alpha: 0.8),
                        width: isSelected ? 1.8 : (isToday ? 1.4 : 1.0),
                      ),
                      boxShadow: context.appTileShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Day name + Today chip + Meal count chip + Chevron
                        Row(
                          children: [
                            Text(
                              DateFormat('EEEE, d MMM').format(date),
                              style: TextStyle(
                                color: context.appText,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'planner.today'.tr,
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    meals.length == 4
                                        ? AppColors.primaryGreen
                                        : (meals.isNotEmpty
                                            ? context.appSoftGreen
                                            : context.appSurfaceLow),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${meals.length}/4 ${'planner.meals'.tr}',
                                style: TextStyle(
                                  color:
                                      meals.length == 4
                                          ? Colors.white
                                          : (meals.isNotEmpty
                                              ? AppColors.primaryGreen
                                              : context.appMutedText),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.appMutedText,
                              size: 19,
                            ),
                          ],
                        ),

                        // Nutrition summary badge for the day
                        if (meals.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.appSurfaceLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'planner.day_calories_protein'.trParams({
                                'cal': '$dayCalories',
                                'pro': '${dayProtein.round()}',
                              }),
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // 4 Meal Slots Row with Meal Names, Images, Calories and Eaten Status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              MealPlanSlot.values.map((slot) {
                                final slotMeal = meals.firstWhereOrNull(
                                  (m) => m.slot == slot,
                                );
                                final slotTheme = PlannerSlotTheme.of(slot);
                                final isEaten =
                                    slotMeal?.status == MealPlanStatus.eaten;

                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3.5,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Image thumbnail or placeholder
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 64,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                if (slotMeal != null)
                                                  PlannerMealImage(
                                                    meal: slotMeal,
                                                    width: double.infinity,
                                                    height: 64,
                                                    radius: 12,
                                                  )
                                                else
                                                  Container(
                                                    color:
                                                        context.appIsDark
                                                            ? slotTheme.soft
                                                                .withValues(
                                                                  alpha: 0.12,
                                                                )
                                                            : slotTheme.soft
                                                                .withValues(
                                                                  alpha: 0.45,
                                                                ),
                                                    child: Center(
                                                      child: Icon(
                                                        slotTheme.icon,
                                                        size: 20,
                                                        color: slotTheme.accent
                                                            .withValues(
                                                              alpha: 0.65,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                if (isEaten)
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            2.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                            blurRadius: 3,
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        size: 13,
                                                        color:
                                                            AppColors
                                                                .primaryGreen,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),

                                        // Slot label
                                        Text(
                                          slot.labelKey.tr,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: slotTheme.accent,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),

                                        // Meal Dish Title or Empty text
                                        Text(
                                          slotMeal != null
                                              ? slotMeal.name
                                              : 'planner.empty_slot_prompt'.tr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                slotMeal != null
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                            color:
                                                slotMeal != null
                                                    ? context.appText
                                                    : context.appMutedText
                                                        .withValues(alpha: 0.7),
                                            fontStyle:
                                                slotMeal == null
                                                    ? FontStyle.italic
                                                    : FontStyle.normal,
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        // Calories
                                        if (slotMeal != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${(slotMeal.calories * slotMeal.servings).round()} kcal',
                                            style: const TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
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
      ),
    );
  });

  Widget _weeklyProgressDashboard(
    BuildContext context,
    MealPlannerController controller,
  ) {
    final totalPlannedMeals = controller.weeklyMealCount;
    final totalPossibleMeals = controller.planDaysCount.value * 4;
    final progress = controller.weeklyProgress.clamp(0.0, 1.0);
    final eatenCount = controller.weeklyEatenMeals;

    int totalWeekCalories = 0;
    double totalWeekProtein = 0.0;
    for (final day in controller.weekDays) {
      for (final meal in controller.mealsFor(day)) {
        totalWeekCalories += (meal.calories * meal.servings).round();
        totalWeekProtein += (meal.proteinGrams * meal.servings);
      }
    }
    final daysCount =
        controller.planDaysCount.value > 0 ? controller.planDaysCount.value : 7;
    final avgCalories = (totalWeekCalories / daysCount).round();
    final avgProtein = (totalWeekProtein / daysCount).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showWeeklyReportDialog(context, controller),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appSoftGreen,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Goal pill + tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF0F62FE,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_down_rounded,
                          size: 13,
                          color: Color(0xFF0F62FE),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'planner.goal_lose_weight'.tr,
                          style: const TextStyle(
                            color: Color(0xFF0F62FE),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'planner.weekly_progress'.tr,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle: Circular progress ring + meals planned text
              Row(
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6.5,
                            backgroundColor: context.appBorder,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        Icon(
                          progress >= 1.0
                              ? Icons.emoji_events_rounded
                              : Icons.restaurant_rounded,
                          size: 22,
                          color: AppColors.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'planner.meals_planned'.trParams({
                                'count': '$totalPlannedMeals',
                                'total': '$totalPossibleMeals',
                              }),
                              style: TextStyle(
                                color: context.appText,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: context.appBorder,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        if (eatenCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'planner.meals_eaten_count'.trParams({
                              'eaten': '$eatenCount',
                              'total': '$totalPlannedMeals',
                            }),
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom Nutritional Daily Averages Row
              if (totalPlannedMeals > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.appElevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.appBorder.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 15,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'planner.avg_daily_calories'.trParams({
                              'kcal': '$avgCalories',
                            }),
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 14, color: context.appBorder),
                      Row(
                        children: [
                          const Icon(
                            Icons.fitness_center_rounded,
                            size: 14,
                            color: Color(0xFF0F62FE),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'planner.avg_daily_protein'.trParams({
                              'protein': '$avgProtein',
                            }),
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
  bool _showWeek = false;

  @override
  void initState() {
    super.initState();
    _showWeek =
        controller.groceryItemsForDate(controller.selectedDate).isEmpty &&
        controller.groceryItems.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items =
          _showWeek
              ? controller.groceryItems
              : controller.groceryItemsForDate(controller.selectedDate);
      final grouped = <String, List<GroceryItem>>{};
      for (final item in items) {
        (grouped[item.category] ??= []).add(item);
      }
      final totalItems = items.length;
      final checkedCount =
          items.where((item) => checked.contains(item.key)).length;

      return _PlannerScaffold(
        header: PlannerPageHeader(
          title: 'planner.grocery_list'.tr,
          trailing:
              totalItems > 0
                  ? TextButton(
                    onPressed: () {
                      setState(() {
                        if (checkedCount == totalItems) {
                          checked.removeAll(items.map((i) => i.key));
                        } else {
                          checked.addAll(items.map((i) => i.key));
                        }
                      });
                    },
                    child: Text(
                      checkedCount == totalItems
                          ? 'planner.uncheck_all'.tr
                          : 'planner.check_all'.tr,
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
                : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => controller.copyGroceryListToClipboard(
                              date: _showWeek ? null : controller.selectedDate,
                            ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text('planner.copy_list'.tr),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(color: AppColors.primaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PlannerPrimaryButton(
                        label: 'planner.share_list'.tr,
                        icon: Icons.share_outlined,
                        onPressed: () async {
                          final lines = items
                              .map(
                                (i) =>
                                    '${checked.contains(i.key) ? '☑' : '☐'} ${i.name.tr}${i.quantityLabel.isEmpty ? '' : ' — ${i.quantityLabel}'}',
                              )
                              .join('\n');
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                                  '${'planner.grocery_list'.tr}\n${_showWeek ? _range(controller.weekStart, controller.weekDays.last) : DateFormat('EEE, d MMM yyyy').format(controller.selectedDate)}\n\n$lines',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        child: LoadingContentTransition(
          isLoading:
              !controller.hasLoadedOnce.value || controller.isLoading.value,
          loading: const PageSkeleton.plannerGrocery(),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groceryScopeSelector(context),
              const SizedBox(height: 18),
              if (grouped.isEmpty)
                _EmptyGrocery(showWeek: _showWeek)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'planner.organized_grocery_list'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'planner.grocery_checked_progress'.trParams({
                              'checked': '$checkedCount',
                              'total': '$totalItems',
                            }),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: checkedCount / totalItems,
                              minHeight: 7,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
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
                                    border: Border.all(
                                      color: context.appBorder,
                                    ),
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
                                  child: InkWell(
                                    key: ValueKey(
                                      'grocery-page-item-${item.key}',
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    onTap:
                                        () => setState(
                                          () =>
                                              isItemChecked
                                                  ? checked.remove(item.key)
                                                  : checked.add(item.key),
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          IngredientAvatar(
                                            name: item.name,
                                            size: 48,
                                            borderRadius: 12,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name.tr,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13.5,
                                                    color:
                                                        isItemChecked
                                                            ? context
                                                                .appMutedText
                                                            : context.appText,
                                                    decoration:
                                                        isItemChecked
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                  ),
                                                ),
                                                if (item
                                                    .sourceMeals
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.sourceMeals.length == 1
                                                        ? 'planner.grocery_from_meal'
                                                            .trParams({
                                                              'name':
                                                                  item
                                                                      .sourceMeals
                                                                      .single,
                                                            })
                                                        : 'planner.grocery_from_meal_count'
                                                            .trParams({
                                                              'count':
                                                                  '${item.sourceMeals.length}',
                                                            }),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          context.appMutedText,
                                                      fontSize: 10.5,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (item
                                              .quantityLabel
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 5),
                                            Text(
                                              item.quantityLabel,
                                              style: const TextStyle(
                                                color: AppColors.primaryGreen,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                          Checkbox(
                                            value: isItemChecked,
                                            activeColor: AppColors.primaryGreen,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onChanged:
                                                (value) => setState(
                                                  () =>
                                                      value == true
                                                          ? checked.add(
                                                            item.key,
                                                          )
                                                          : checked.remove(
                                                            item.key,
                                                          ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
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
            ],
          ),
        ),
      );
    });
  }

  Widget _groceryScopeSelector(BuildContext context) {
    final dayLabel = DateFormat('EEE, d MMM').format(controller.selectedDate);
    final weekLabel = _range(controller.weekStart, controller.weekDays.last);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'planner.grocery_plan_ingredients'.tr,
          style: TextStyle(
            color: context.appText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _showWeek ? weekLabel : dayLabel,
          style: TextStyle(color: context.appMutedText, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _scopeButton(
                context,
                selected: !_showWeek,
                label: 'planner.grocery_selected_day'.tr,
                icon: Icons.today_rounded,
                onTap: () => setState(() => _showWeek = false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _scopeButton(
                context,
                selected: _showWeek,
                label: 'planner.grocery_full_week'.tr,
                icon: Icons.date_range_rounded,
                onTap: () => setState(() => _showWeek = true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scopeButton(
    BuildContext context, {
    required bool selected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 17),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      backgroundColor:
          selected ? context.appSoftGreen : context.appElevatedSurface,
      foregroundColor: selected ? AppColors.primaryGreen : context.appMutedText,
      side: BorderSide(
        color: selected ? AppColors.primaryGreen : context.appBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );

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
  const _EmptyGrocery({required this.showWeek});

  final bool showWeek;

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
              (showWeek
                      ? 'planner.empty_grocery_list'
                      : 'planner.empty_day_grocery_list')
                  .tr,
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
    key: const ValueKey('planner-flow-week-card'),
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
      boxShadow: context.appTileShadow,
    ),
    child: Column(
      children: [
        Row(
          children: [
            _flowWeekArrow(context, Icons.chevron_left_rounded, -1),
            Expanded(
              child: InkWell(
                key: const ValueKey('planner-flow-week-picker-button'),
                onTap: () => _pickWeekDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'planner.selected_week'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _range(
                                controller.weekStart,
                                controller.weekDays.last,
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 18,
                              color: context.appMutedText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _flowWeekArrow(context, Icons.chevron_right_rounded, 1),
            const SizedBox(width: 6),
            InkWell(
              key: const ValueKey('planner-flow-week-today-button'),
              onTap: () => controller.goToToday(),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'planner.today'.tr,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 14, color: context.appMutedText),
                const SizedBox(width: 5),
                Text(
                  'planner.duration'.tr,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        [3, 4, 5, 6, 7].map((days) {
                          final isSelected =
                              controller.planDaysCount.value == days;
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: InkWell(
                              key: ValueKey('flow-duration-$days'),
                              onTap: () => controller.setPlanDaysCount(days),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                constraints: const BoxConstraints(minWidth: 30),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.primaryGreen
                                          : context.appBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primaryGreen
                                            : context.appBorder.withValues(
                                              alpha: 0.65,
                                            ),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  '$days${'planner.days_short'.tr}',
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : context.appText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child:
              controller.weekDays.length <= 5
                  ? Row(
                    children: List.generate(controller.weekDays.length, (
                      index,
                    ) {
                      final date = controller.weekDays[index];
                      final selected =
                          index == controller.selectedDayIndex.value;
                      final hasMeals = controller.mealsFor(date).isNotEmpty;
                      const weekDayKeys = [
                        'planner.mon',
                        'planner.tue',
                        'planner.wed',
                        'planner.thu',
                        'planner.fri',
                        'planner.sat',
                        'planner.sun',
                      ];
                      final gap = controller.weekDays.length <= 3 ? 12.0 : 8.0;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right:
                                index == controller.weekDays.length - 1
                                    ? 0
                                    : gap,
                          ),
                          child: InkWell(
                            onTap: () => controller.selectDay(index),
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? AppColors.primaryGreen
                                        : context.appBackground,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      selected
                                          ? AppColors.primaryGreen
                                          : context.appBorder.withValues(
                                            alpha: 0.6,
                                          ),
                                  width: 1.0,
                                ),
                                boxShadow:
                                    selected
                                        ? [
                                          BoxShadow(
                                            color: AppColors.primaryGreen
                                                .withValues(alpha: 0.28),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    weekDayKeys[date.weekday - 1].tr,
                                    style: TextStyle(
                                      color:
                                          selected
                                              ? Colors.white
                                              : context.appMutedText,
                                      fontSize: 11,
                                      fontWeight:
                                          selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color:
                                          selected
                                              ? Colors.white
                                              : context.appText,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: BoxDecoration(
                                      color:
                                          hasMeals
                                              ? (selected
                                                  ? Colors.white
                                                  : AppColors.primaryGreen)
                                              : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  )
                  : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.weekDays.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final date = controller.weekDays[index];
                      final selected =
                          index == controller.selectedDayIndex.value;
                      final hasMeals = controller.mealsFor(date).isNotEmpty;
                      const weekDayKeys = [
                        'planner.mon',
                        'planner.tue',
                        'planner.wed',
                        'planner.thu',
                        'planner.fri',
                        'planner.sat',
                        'planner.sun',
                      ];
                      return InkWell(
                        onTap: () => controller.selectDay(index),
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 60,
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? AppColors.primaryGreen
                                    : context.appBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  selected
                                      ? AppColors.primaryGreen
                                      : context.appBorder.withValues(
                                        alpha: 0.6,
                                      ),
                              width: 1.0,
                            ),
                            boxShadow:
                                selected
                                    ? [
                                      BoxShadow(
                                        color: AppColors.primaryGreen
                                            .withValues(alpha: 0.28),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weekDayKeys[date.weekday - 1].tr,
                                style: TextStyle(
                                  color:
                                      selected
                                          ? Colors.white
                                          : context.appMutedText,
                                  fontSize: 11,
                                  fontWeight:
                                      selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : context.appText,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: 4.5,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color:
                                      hasMeals
                                          ? (selected
                                              ? Colors.white
                                              : AppColors.primaryGreen)
                                          : Colors.transparent,
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

  Future<void> _pickWeekDate(BuildContext context) async {
    DateTime selectedStart = controller.planStartDate;
    int selectedDays = controller.planDaysCount.value;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.appSurfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              final previewEnd = selectedStart.add(
                Duration(days: selectedDays - 1),
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: context.appBorder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'planner.custom_plan'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'planner.choose_duration'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'planner.duration'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          [3, 4, 5, 6, 7].map((days) {
                            final isSel = selectedDays == days;
                            return InkWell(
                              onTap:
                                  () =>
                                      setSheetState(() => selectedDays = days),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSel
                                          ? AppColors.primaryGreen
                                          : context.appElevatedSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSel
                                            ? AppColors.primaryGreen
                                            : context.appBorder.withValues(
                                              alpha: 0.8,
                                            ),
                                  ),
                                ),
                                child: Text(
                                  '$days${'planner.days_short'.tr}',
                                  style: TextStyle(
                                    color:
                                        isSel ? Colors.white : context.appText,
                                    fontSize: 13,
                                    fontWeight:
                                        isSel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'planner.start_date'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedStart,
                          firstDate: DateTime(now.year - 2),
                          lastDate: DateTime(now.year + 2, 12, 31),
                          helpText: 'planner.select_date'.tr,
                          cancelText: 'planner.cancel'.tr,
                          confirmText: 'planner.select'.tr,
                          builder: (pickerContext, child) {
                            final isDark =
                                Theme.of(pickerContext).brightness ==
                                Brightness.dark;
                            return Theme(
                              data: Theme.of(pickerContext).copyWith(
                                colorScheme: ColorScheme.fromSeed(
                                  seedColor: AppColors.primaryGreen,
                                  primary: AppColors.primaryGreen,
                                  onPrimary: Colors.white,
                                  surface: pickerContext.appElevatedSurface,
                                  onSurface: pickerContext.appText,
                                  brightness:
                                      isDark
                                          ? Brightness.dark
                                          : Brightness.light,
                                ),
                              ),
                              child: child ?? const SizedBox.shrink(),
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => selectedStart = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.appElevatedSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: context.appBorder.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy',
                                ).format(selectedStart),
                                style: TextStyle(
                                  color: context.appText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 18,
                              color: context.appMutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${DateFormat('d MMM').format(selectedStart)} – ${DateFormat('d MMM yyyy').format(previewEnd)} ($selectedDays ${'planner.days_short'.tr.trim()})',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PlannerPrimaryButton(
                      label: 'planner.apply'.tr,
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        controller.setCustomPlanRange(
                          start: selectedStart,
                          days: selectedDays,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _flowWeekArrow(BuildContext context, IconData icon, int amount) =>
      InkWell(
        onTap: () => controller.changeWeek(amount),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.appBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: context.appBorder.withValues(alpha: 0.55),
            ),
          ),
          child: Center(child: Icon(icon, size: 20, color: context.appText)),
        ),
      );
}

String _range(DateTime start, DateTime end) =>
    '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
