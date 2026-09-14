import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../translations/localized_text.dart';
import '../../../models/community/community_post.dart';

Future<void> showCommunityRecipeSheet(
  BuildContext context,
  CommunityPost post,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: .5),
  builder: (_) => _CommunityRecipeSheet(post: post),
);

class _CommunityRecipeSheet extends StatelessWidget {
  const _CommunityRecipeSheet({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: height * .82),
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RecipeHeader(post: post),
                    if (_hasMeta(post)) ...[
                      const SizedBox(height: 13),
                      _RecipeMeta(post: post),
                    ],
                    if (post.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SectionTitle(
                        label: 'common.ingredients'.tr,
                        icon: Icons.eco_outlined,
                      ),
                      const SizedBox(height: 11),
                      _IngredientGrid(items: post.ingredients),
                    ],
                    if (post.steps.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SectionTitle(
                        label: 'community.how_to_cook'.tr,
                        icon: Icons.restaurant_menu_rounded,
                      ),
                      const SizedBox(height: 11),
                      ...post.steps.map(_RecipeStep.new),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _hasMeta(CommunityPost post) =>
      post.cookingTimeMinutes != null ||
      post.servings != null ||
      post.difficulty.isNotEmpty;
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 9),
    child: Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: context.appBorder,
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );
}

class _RecipeHeader extends StatelessWidget {
  const _RecipeHeader({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFDDF8E8),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.restaurant_rounded,
          color: AppColors.primaryGreen,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'community.recipe_details'.tr,
              style: TextStyle(
                color: context.appText,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              post.mealName,
              style: TextStyle(fontSize: 12, color: context.appMutedText),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'common.close'.tr,
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );
}

class _RecipeMeta extends StatelessWidget {
  const _RecipeMeta({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (post.cookingTimeMinutes != null)
        _MetaPill(
          Icons.schedule_rounded,
          '${post.cookingTimeMinutes} ${'meals.minutes_short'.tr}',
        ),
      if (post.servings != null)
        _MetaPill(
          Icons.people_outline_rounded,
          'meals.servings_count'.trParams({'count': '${post.servings}'}),
        ),
      if (post.difficulty.isNotEmpty)
        _MetaPill(
          Icons.local_fire_department_outlined,
          _localizedDifficulty(post.difficulty),
        ),
    ],
  );

  String _localizedDifficulty(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'EASY' => 'meals.easy'.tr,
      'MEDIUM' => 'common.medium'.tr,
      'HARD' => 'meals.hard'.tr,
      _ => value.trOrSelf,
    };
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFDDF8E8),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFF9CDFB7)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primaryGreen),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      const SizedBox(width: 10),
      Expanded(child: Divider(color: context.appBorder)),
      const SizedBox(width: 8),
      Icon(icon, size: 17, color: AppColors.primaryGreen),
    ],
  );
}

class _IngredientGrid extends StatelessWidget {
  const _IngredientGrid({required this.items});

  final List<MealPostIngredient> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSoftGreen,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.ingredientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _amount(item),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      );
    },
  );

  static String _amount(MealPostIngredient item) {
    final amount = item.amount;
    final number =
        amount == null ? '' : '$amount'.replaceFirst(RegExp(r'\.0$'), '');
    final value = '$number ${item.unit}'.trim();
    return value.isEmpty ? '—' : value;
  }
}

class _RecipeStep extends StatelessWidget {
  const _RecipeStep(this.step);

  final MealPostStep step;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.primaryGreen,
          child: Text(
            '${step.stepNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 30),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              step.instruction,
              style: const TextStyle(fontSize: 12.5, height: 1.3),
            ),
          ),
        ),
      ],
    ),
  );
}
