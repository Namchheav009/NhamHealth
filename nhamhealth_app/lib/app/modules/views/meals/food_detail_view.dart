import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/meals/food_detail_controller.dart';
import '../../models/meals/meal_model.dart';

class FoodDetailView extends GetView<FoodDetailController> {
  const FoodDetailView({super.key});

  static const green = AppColors.primaryGreen;
  static const darkGreen = AppColors.darkGreen;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.15,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(child: Obx(() => _body(context))),
    ),
  );

  Widget _body(BuildContext context) {
    final meal = controller.meal;
    if (meal == null) {
      if (controller.isLoading.value) {
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 34),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: const PageSkeleton.foodDetail(),
              ),
            ),
          ),
        );
      }
      return Center(
        child: _LoadError(
          message: controller.errorMessage.value,
          onRetry: controller.loadDetail,
        ),
      );
    }
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 34),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailHeader(
                      onBack: controller.goBack,
                      isFavorite: controller.isFavorite.value,
                      onFavorite: controller.toggleFavorite,
                    ),
                    const SizedBox(height: 12),
                    _Hero(meal: meal),
                    const SizedBox(height: 22),
                    _Introduction(meal: meal),
                    const SizedBox(height: 22),
                    _Nutrition(meal: meal),
                    const SizedBox(height: 22),
                    _Stats(meal: meal),
                    const SizedBox(height: 24),
                    _Tabs(
                      selected: controller.selectedContentTab.value,
                      ingredientCount: meal.ingredients.length,
                      stepCount: meal.steps.length,
                      onSelected: controller.selectContentTab,
                    ),
                    const SizedBox(height: 18),
                    if (!controller.isDetailLoaded.value)
                      _ContentLoading(
                        error: controller.errorMessage.value,
                        onRetry: controller.loadDetail,
                      )
                    else if (controller.selectedContentTab.value == 0)
                      _Ingredients(items: meal.ingredients)
                    else
                      _Steps(items: meal.steps),
                  ],
                ),
              ),
            ),
          ),
          if (controller.isLoading.value)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2, color: green),
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.meal});
  final MealModel meal;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appCardShadow,
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      height: 264,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroImage(imageUrl: meal.image),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0x66002716), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: _Category(category: meal.category),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: _Category(category: meal.category),
          ),
        ],
      ),
    ),
  );
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onBack,
    required this.isFavorite,
    required this.onFavorite,
  });

  final VoidCallback onBack;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppBackButton.layoutSize,
    child: Row(
      children: [
        AppBackButton(onPressed: onBack),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Food Detail'.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _HeaderFavorite(selected: isFavorite, onPressed: onFavorite),
      ],
    ),
  );
}

class _HeaderFavorite extends StatelessWidget {
  const _HeaderFavorite({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppBackButton.layoutSize,
    child: Padding(
      padding: AppBackButton.outerMargin,
      child: Material(
        color: Colors.white.withValues(alpha: .95),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: selected ? AppColors.favoriteRed : const Color(0xFF8A8D8B),
            size: 20,
          ),
        ),
      ),
    ),
  );
}

class _Category extends StatelessWidget {
  const _Category({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color:
          context.appIsDark
              ? context.appElevatedSurface.withValues(alpha: .94)
              : Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.appBorder.withValues(alpha: .7)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          category,
          style: TextStyle(
            color: context.appColorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          category,
          style: TextStyle(
            color: context.appColorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 9),
          child: SizedBox(
            width: 3,
            height: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appMutedText,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Text(
          'Healthy recipe',
          style: TextStyle(color: context.appMutedText, fontSize: 12),
        ),
        Text(
          'Healthy recipe',
          style: TextStyle(color: context.appMutedText, fontSize: 12),
        ),
      ],
    ),
  );
}

class _Introduction extends StatelessWidget {
  const _Introduction({required this.meal});
  final MealModel meal;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        meal.name,
        style: TextStyle(
          color: context.appText,
          fontSize: 27,
          height: 1.08,
          fontWeight: FontWeight.w800,
        ),
        style: TextStyle(
          color: context.appText,
          fontSize: 27,
          height: 1.08,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        meal.description.isEmpty
            ? 'A nourishing choice for your day'.tr
            : meal.description,
        style: TextStyle(
          color: context.appMutedText,
          fontSize: 13,
          height: 1.4,
        ),
        meal.description.isEmpty
            ? 'A nourishing choice for your day'.tr
            : meal.description,
        style: TextStyle(
          color: context.appMutedText,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _Nutrition extends StatelessWidget {
  const _Nutrition({required this.meal});
  final MealModel meal;

  @override
  Widget build(BuildContext context) {
    final nutrition = _keyNutrition(meal.nutrition);
    final maxAmount = nutrition.fold<double>(
      1,
      (max, item) =>
          item.amount.toDouble() > max ? item.amount.toDouble() : max,
    );
    final maxAmount = nutrition.fold<double>(
      1,
      (max, item) =>
          item.amount.toDouble() > max ? item.amount.toDouble() : max,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${meal.calories}',
              style: TextStyle(
                color:
                    context.appIsDark
                        ? context.appColorScheme.primary
                        : FoodDetailView.darkGreen,
                fontSize: 46,
                height: .9,
                fontWeight: FontWeight.w800,
              ),
              style: TextStyle(
                color:
                    context.appIsDark
                        ? context.appColorScheme.primary
                        : FoodDetailView.darkGreen,
                fontSize: 46,
                height: .9,
                fontWeight: FontWeight.w800,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 95),
              child: Text(
                'kcal',
                style: TextStyle(color: context.appMutedText, fontSize: 12),
              ),
              child: Text(
                'kcal',
                style: TextStyle(color: context.appMutedText, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(width: 26),
        Expanded(
          child:
              nutrition.isEmpty
                  ? const SizedBox(height: 58)
                  : Column(
                    children: nutrition
                        .map(
                          (item) =>
                              _NutritionRow(item: item, maxAmount: maxAmount),
                        )
                        .toList(growable: false),
                  ),
          child:
              nutrition.isEmpty
                  ? const SizedBox(height: 58)
                  : Column(
                    children: nutrition
                        .map(
                          (item) =>
                              _NutritionRow(item: item, maxAmount: maxAmount),
                        )
                        .toList(growable: false),
                  ),
        ),
      ],
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.item, required this.maxAmount});
  final MealNutritionModel item;
  final double maxAmount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            item.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              value: item.amount.toDouble() / maxAmount,
              minHeight: 6,
              color: context.appColorScheme.primary,
              backgroundColor: context.appSoftGreen,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 38,
          child: Text(
            '${_format(item.amount)} ${item.unit}',
            textAlign: TextAlign.right,
            style: TextStyle(color: context.appText, fontSize: 10.5),
          ),
        ),
      ],
    ),
  );
}

class _Stats extends StatelessWidget {
  const _Stats({required this.meal});
  final MealModel meal;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: context.appBorder),
      ),
    ),
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: context.appBorder),
      ),
    ),
    child: Row(
      children: [
        _Stat(
          icon: Icons.schedule_rounded,
          label: 'Cook time',
          value: _withUnit(meal.cookingTimeMinutes, 'mins'),
        ),
        _Stat(
          icon: Icons.schedule_rounded,
          label: 'Cook time',
          value: _withUnit(meal.cookingTimeMinutes, 'mins'),
        ),
        const _StatDivider(),
        _Stat(
          icon: Icons.local_fire_department_outlined,
          label: 'Difficulty',
          value: meal.difficulty.isEmpty ? 'Not specified' : meal.difficulty,
        ),
        _Stat(
          icon: Icons.local_fire_department_outlined,
          label: 'Difficulty',
          value: meal.difficulty.isEmpty ? 'Not specified' : meal.difficulty,
        ),
        const _StatDivider(),
        _Stat(
          icon: Icons.people_outline_rounded,
          label: 'Servings',
          value: _withUnit(meal.servings, 'people'),
        ),
        _Stat(
          icon: Icons.people_outline_rounded,
          label: 'Servings',
          value: _withUnit(meal.servings, 'people'),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: context.appColorScheme.primary, size: 20),
        const SizedBox(height: 7),
        Text(
          label.tr,
          style: TextStyle(color: context.appMutedText, fontSize: 10),
        ),
        Text(
          label.tr,
          style: TextStyle(color: context.appMutedText, fontSize: 10),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.appText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.appText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 62, child: VerticalDivider(color: context.appBorder));
  Widget build(BuildContext context) =>
      SizedBox(height: 62, child: VerticalDivider(color: context.appBorder));
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.ingredientCount,
    required this.stepCount,
    required this.onSelected,
  });
  const _Tabs({
    required this.selected,
    required this.ingredientCount,
    required this.stepCount,
    required this.onSelected,
  });
  final int selected;
  final int ingredientCount;
  final int stepCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: context.appBorder),
    ),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: context.appBorder),
    ),
    child: Row(
      children: [
        _Tab(
          label: 'Ingredients',
          count: ingredientCount,
          selected: selected == 0,
          onTap: () => onSelected(0),
        ),
        _Tab(
          label: 'How to make',
          count: stepCount,
          selected: selected == 1,
          onTap: () => onSelected(1),
        ),
        _Tab(
          label: 'Ingredients',
          count: ingredientCount,
          selected: selected == 0,
          onTap: () => onSelected(0),
        ),
        _Tab(
          label: 'How to make',
          count: stepCount,
          selected: selected == 1,
          onTap: () => onSelected(1),
        ),
      ],
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  const _Tab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: selected ? context.appColorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '${label.tr} - $count',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  selected
                      ? context.appColorScheme.onPrimary
                      : context.appColorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            style: TextStyle(
              color:
                  selected
                      ? context.appColorScheme.onPrimary
                      : context.appColorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Ingredients extends StatelessWidget {
  const _Ingredients({required this.items});
  final List<MealIngredientModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty(message: 'No ingredients available');
    return Container(
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder.withValues(alpha: .42)),
        boxShadow: context.appTileShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: List.generate(
            items.length,
            (index) => _IngredientRow(
              item: items[index],
              showDivider: index < items.length - 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.item, required this.showDivider});

  final MealIngredientModel item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: context.appColorScheme.primary,
                size: 15,
              ),
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: context.appColorScheme.primary,
                size: 15,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.preparationNote.isEmpty
                    ? item.name
                    : '${item.name}, ${item.preparationNote}',
                item.preparationNote.isEmpty
                    ? item.name
                    : '${item.name}, ${item.preparationNote}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                style: TextStyle(
                  color: context.appText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              constraints: const BoxConstraints(minWidth: 54),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _ingredientAmount(item),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                style: TextStyle(
                  color: context.appColorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      if (showDivider)
        Padding(
          padding: EdgeInsets.only(left: 53, right: 15),
          child: Divider(height: 1, color: context.appBorder),
        ),
    ],
  );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.items});
  final List<MealStepModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _Empty(message: 'No cooking steps available');
    }
    return Column(
      children: items
          .asMap()
          .entries
          .map(
            (entry) => _Step(step: entry.value, fallbackNumber: entry.key + 1),
          )
          .toList(growable: false),
      children: items
          .asMap()
          .entries
          .map(
            (entry) => _Step(step: entry.value, fallbackNumber: entry.key + 1),
          )
          .toList(growable: false),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.step, required this.fallbackNumber});
  final MealStepModel step;
  final int fallbackNumber;

  @override
  Widget build(BuildContext context) {
    final number = step.number <= 0 ? fallbackNumber : step.number;
    return Container(
      padding: const EdgeInsets.only(bottom: 17),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: context.appColorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: context.appColorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 14,
                    height: 1.45,
                  ),
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentLoading extends StatelessWidget {
  const _ContentLoading({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child:
        error.isEmpty
            ? const PageSkeleton.foodDetailContent()
            : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appMutedText),
                  ),
                  TextButton(onPressed: onRetry, child: Text('Try again'.tr)),
                ],
              ),
            ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 34),
    child: Center(
      child: Text(
        message.tr,
        style: TextStyle(color: context.appMutedText, fontSize: 14),
      ),
    ),
    child: Center(
      child: Text(
        message.tr,
        style: TextStyle(color: context.appMutedText, fontSize: 14),
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 36),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.restaurant_menu_rounded,
          color: context.appColorScheme.primary,
          size: 42,
        ),
        Icon(
          Icons.restaurant_menu_rounded,
          color: context.appColorScheme.primary,
          size: 42,
        ),
        const SizedBox(height: 12),
        Text(
          message.isEmpty ? 'Meal details are unavailable.' : message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appMutedText, fontSize: 14),
        ),
        Text(
          message.isEmpty ? 'Meal details are unavailable.' : message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appMutedText, fontSize: 14),
        ),
        TextButton(onPressed: onRetry, child: Text('Try again'.tr)),
      ],
    ),
  );
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl});
  final String imageUrl;
  static const _fallback = 'assets/images/food_detail/salad.png';

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() => Image.asset(_fallback, fit: BoxFit.cover);
}

List<MealNutritionModel> _keyNutrition(List<MealNutritionModel> source) {
  const keywords = ['protein', 'carb', 'fat'];
  final selected = <MealNutritionModel>[];
  for (final keyword in keywords) {
    for (final item in source) {
      if (item.name.toLowerCase().contains(keyword) &&
          !selected.contains(item)) {
      if (item.name.toLowerCase().contains(keyword) &&
          !selected.contains(item)) {
        selected.add(item);
        break;
      }
    }
  }
  for (final item in source) {
    if (selected.length == 3) break;
    if (!selected.contains(item)) selected.add(item);
  }
  return selected;
}

String _withUnit(int? value, String unit) =>
    value == null ? 'Not specified' : '$value $unit';
String _ingredientAmount(MealIngredientModel item) =>
    item.quantity == null
        ? (item.description.isEmpty ? '—' : item.description)
        : '${_format(item.quantity!)} ${item.unit}'.trim();
String _format(num value) =>
    value.toDouble() == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
String _withUnit(int? value, String unit) =>
    value == null ? 'Not specified' : '$value $unit';
String _ingredientAmount(MealIngredientModel item) =>
    item.quantity == null
        ? (item.description.isEmpty ? '—' : item.description)
        : '${_format(item.quantity!)} ${item.unit}'.trim();
String _format(num value) =>
    value.toDouble() == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
