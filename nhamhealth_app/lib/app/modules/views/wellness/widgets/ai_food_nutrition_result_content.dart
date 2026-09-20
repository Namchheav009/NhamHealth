import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_nutrient_theme.dart';
import '../../../controllers/wellness/ai_food_controller.dart';
import '../../../models/wellness/food_nutrition_model.dart';
import 'ai_food_amount_sheet.dart';

class AiFoodNutritionResultContent extends StatelessWidget {
  const AiFoodNutritionResultContent({
    super.key,
    required this.controller,
    this.food,
  });

  final AiFoodController controller;
  final FoodNutritionModel? food;

  static const Color green = Color(0xFF00A651);
  static const Color greenDark = Color(0xFF087A48);
  static const Color greenLightBg = Color(0xFFEAF7EE);
  static const Color greenBorder = Color(0xFF86EFAC);
  static const Color warn = Color(0xFFFF7A45);

  FoodNutritionModel get _food => food ?? controller.nutrition.value!;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroCard(context, _food),
          const SizedBox(height: 12),
          _buildAmountCard(context),
          const SizedBox(height: 14),
          _buildPlateBreakdownButton(context),
          if (_food.needsUserConfirmation &&
              !controller.isUserConfirmed.value) ...[
            const SizedBox(height: 14),
            _buildReviewCard(context, _food),
          ],
          const SizedBox(height: 14),
          _buildNutritionEstimateCard(context, _food),
          const SizedBox(height: 14),
          _buildSugarAnalysisCard(context, _food),
          const SizedBox(height: 14),
          _buildAiRecommendationCard(context, _food),
          const SizedBox(height: 14),
          _buildLegalNotice(context, _food),
        ],
      ),
    );
  }

  // ---- 1. Hero Food Card ----------------------------------------------------
  Widget _buildHeroCard(BuildContext context, FoodNutritionModel food) {
    final imageFile = controller.selectedImage.value;
    final tags = controller.foodTags;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 245,
        width: double.infinity,
        color: Colors.black87,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background food image
            if (imageFile != null)
              Image.file(
                imageFile,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildImagePlaceholder(),
              )
            else
              _buildImagePlaceholder(),

            // Gradient shadow overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),

            // Top-right "AI Recognized" badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: green, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'AI Recognized',
                      style: TextStyle(
                        color: green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom food metadata overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    food.mealName.isNotEmpty ? food.mealName : food.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (food.cuisine != 'Unknown' && food.cuisine.isNotEmpty)
                        food.cuisine,
                      food.mealType == 'mixed'
                          ? 'Food & Drink'
                          : food.mealType == 'drink'
                          ? 'Drink'
                          : 'Dish',
                    ].join(' • '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children:
                            tags.map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        size: 54,
        color: Colors.white38,
      ),
    );
  }

  // ---- 2. Amount / Portion Card ---------------------------------------------
  Widget _buildAmountCard(BuildContext context) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF143021) : greenLightBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              _food.requiresDrinkDetails || _food.mealType == 'drink'
                  ? Icons.local_drink_rounded
                  : Icons.restaurant_rounded,
              color: green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'wellness.amount'.trOrSelf,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  controller.selectedAmountLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _food.requiresDrinkDetails || _food.mealType == 'drink'
                      ? 'About ${controller.selectedAmount.round()} ml'
                      : 'About ${controller.estimatedGrams} g',
                  style: TextStyle(color: context.appMutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final updated = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withValues(alpha: .55),
                builder: (_) => AiFoodAmountSheet(controller: controller),
              );
              if (updated == true) {
                controller.updateAmountForCurrentResult();
              }
            },
            icon: const Icon(Icons.edit_outlined, size: 15, color: green),
            label: Text(
              'common.edit'.trOrSelf,
              style: const TextStyle(
                color: green,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: green, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Plate Breakdown Button ----------------------------------------------
  Widget _buildPlateBreakdownButton(BuildContext context) {
    final isDark = context.appIsDark;
    return Obx(() {
      final itemCount = controller.plateItems.length;
      final selectedCount =
          controller.plateItems.where((i) => i.isSelected).length;

      return Container(
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? context.appBorder : const Color(0xFFE5E7EB),
          ),
          boxShadow: context.appCardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Get.toNamed(AppRoutes.plateBreakdown);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF143021) : greenLightBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'wellness.plate_items'.tr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: context.appText,
                              ),
                            ),
                            if (itemCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$selectedCount / $itemCount',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'wellness.view_plate_breakdown_desc'.trOrSelf,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.appMutedText,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---- 3. Review Card (Uncertainty / Candidates) -----------------------------
  Widget _buildReviewCard(BuildContext context, FoodNutritionModel food) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appWarningSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnWarningSurface.withValues(alpha: .3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: warn, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'wellness.review_result'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'wellness.uncertain_result_help'.tr,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (food.candidates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  food.candidates.map((candidate) {
                    final candidateName = candidate.name;
                    final isSelected =
                        candidateName.toLowerCase() == food.name.toLowerCase();
                    return ActionChip(
                      label: Text(candidateName),
                      backgroundColor:
                          isSelected
                              ? green.withValues(alpha: 0.16)
                              : context.appElevatedSurface,
                      side: BorderSide(
                        color:
                            isSelected
                                ? green
                                : context.appBorder.withValues(alpha: .6),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? greenDark : context.appText,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onPressed:
                          () => controller.selectCandidate(candidateName),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ---- 4. Nutrition Estimate Card -------------------------------------------
  Widget _buildNutritionEstimateCard(
    BuildContext context,
    FoodNutritionModel food,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: green, size: 22),
              const SizedBox(width: 8),
              Text(
                'wellness.nutrition_estimate'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'AI estimate',
                  style: TextStyle(
                    color: Color(0xFFFF7A45),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showInfoDialog(context, food),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: context.appMutedText,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-Column Grid (4 rows = 8 metrics)
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  context,
                  icon: AppNutrientTheme.caloriesIcon,
                  iconColor: AppNutrientTheme.caloriesColor,
                  iconBg: AppNutrientTheme.caloriesBg,
                  value: '${food.calories.round()} kcal',
                  label: 'wellness.calories'.tr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  context,
                  icon: AppNutrientTheme.proteinIcon,
                  iconColor: AppNutrientTheme.proteinColor,
                  iconBg: AppNutrientTheme.proteinBg,
                  value: '${food.protein.toStringAsFixed(1)} g',
                  label: 'wellness.protein'.tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  context,
                  icon: AppNutrientTheme.carbsIcon,
                  iconColor: AppNutrientTheme.carbsColor,
                  iconBg: AppNutrientTheme.carbsBg,
                  value: '${food.carbs.toStringAsFixed(1)} g',
                  label: 'wellness.carbs'.tr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  context,
                  icon: AppNutrientTheme.fatIcon,
                  iconColor: AppNutrientTheme.fatColor,
                  iconBg: AppNutrientTheme.fatBg,
                  value: '${food.fat.toStringAsFixed(1)} g',
                  label: 'wellness.fat'.tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  context,
                  icon: AppNutrientTheme.sugarIcon,
                  iconColor: AppNutrientTheme.sugarColor,
                  iconBg: AppNutrientTheme.sugarBg,
                  value: '${food.sugar.toStringAsFixed(1)} g',
                  label: 'wellness.sugar'.tr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  context,
                  icon: AppNutrientTheme.fiberIcon,
                  iconColor: AppNutrientTheme.fiberColor,
                  iconBg: AppNutrientTheme.fiberBg,
                  value: '${food.fiber.toStringAsFixed(1)} g',
                  label: 'wellness.fiber'.tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  context,
                  icon: AppNutrientTheme.waterIcon,
                  iconColor: AppNutrientTheme.waterColor,
                  iconBg: AppNutrientTheme.waterBg,
                  value:
                      food.requiresDrinkDetails || food.mealType == 'drink'
                          ? '${controller.selectedAmount.round()} ml'
                          : '--',
                  label: 'wellness.water'.tr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  context,
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFF16875B),
                  iconBg: const Color(0xFFEAF7EE),
                  value: controller.selectedAmountLabel,
                  label: 'wellness.serving'.tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? context.appSurfaceLow : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? context.appBorder : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.18) : iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appMutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- 5. Sugar Analysis Card -----------------------------------------------
  Widget _buildSugarAnalysisCard(
    BuildContext context,
    FoodNutritionModel food,
  ) {
    final sugar = food.sugar;
    final carbs = food.carbs;
    final sugarTsp = sugar / 4.0;
    final sugarCarbRatio = carbs > 0 ? (sugar / carbs).clamp(0.0, 1.0) : 0.0;
    final sugarSharePercent = (sugarCarbRatio * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.view_in_ar_rounded,
                  color: Color(0xFF9333EA),
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'wellness.sugar_analysis'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EEFD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'wellness.estimate'.tr,
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Column Stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sugar.toStringAsFixed(1)} g',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'wellness.estimated_total_sugar'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sugarTsp.toStringAsFixed(1)} tsp',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'wellness.about_teaspoons'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$sugarSharePercent%',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'wellness.sugar_share_of_carbs'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appMutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: sugarCarbRatio < 0.04 ? 0.05 : sugarCarbRatio,
              backgroundColor: const Color(0xFFF1F3F5),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),

          // Footnote disclaimer
          Text(
            'wellness.this_is_estimated_total_sugar_a_photo_cannot_reliably_separate_added_sugar_from_naturally_occurring_sugar_so_it_is_not_a_daily_value_percentage_check_the_package_label_or_recipe_when_available'
                .tr,
            style: TextStyle(
              fontSize: 11,
              color: context.appMutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 6. AI Recommendation Card --------------------------------------------
  Widget _buildAiRecommendationCard(
    BuildContext context,
    FoodNutritionModel food,
  ) {
    final isDark = context.appIsDark;
    final rec = controller.recommendation.value;
    final title =
        rec != null && rec.title.isNotEmpty
            ? rec.title.trParams(rec.titleParams)
            : food.recommendationTitle.isNotEmpty
            ? food.recommendationTitle
            : 'Strong Protein Choice';
    final message =
        rec != null && rec.message.isNotEmpty
            ? rec.message.trParams(rec.messageParams)
            : food.recommendation.isNotEmpty
            ? food.recommendation
            : 'Provides about ${food.protein.round()} g protein and fits your remaining calories. Add vegetables for fiber.';

    return InkWell(
      onTap: () => _showRecommendationDetails(context, title, message),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F291E) : const Color(0xFFF0FDF4),
          border: Border.all(color: greenBorder, width: 1.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.tips_and_updates_rounded,
                color: green,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'AI Recommendation',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF14532D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appMutedText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: green, size: 24),
          ],
        ),
      ),
    );
  }

  // ---- 7. Legal Notice / Disclaimer -----------------------------------------
  Widget _buildLegalNotice(BuildContext context, FoodNutritionModel food) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appWarningSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.appOnWarningSurface.withValues(alpha: .35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 17,
                color: context.appOnWarningSurface,
              ),
              const SizedBox(width: 7),
              Text(
                'wellness.important_information'.tr,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.appOnWarningSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            food.disclaimer.isNotEmpty
                ? food.disclaimer
                : 'wellness.ai_nutrition_results_are_estimates_for_general_wellness_only_they_are_not_medical_advice_a_diagnosis_or_an_official_nutrition_label'
                    .tr,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: context.appOnWarningSurface.withValues(alpha: .9),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, FoodNutritionModel food) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ctx.appElevatedSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: green, size: 22),
                const SizedBox(width: 8),
                Text(
                  'wellness.important_information'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ctx.appText,
                  ),
                ),
              ],
            ),
            content: Text(
              food.disclaimer.isNotEmpty
                  ? food.disclaimer
                  : 'wellness.ai_nutrition_results_are_estimates_for_general_wellness_only_they_are_not_medical_advice_a_diagnosis_or_an_official_nutrition_label'
                      .tr,
              style: TextStyle(
                fontSize: 13,
                color: ctx.appMutedText,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(color: green, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  void _showRecommendationDetails(
    BuildContext context,
    String title,
    String message,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appElevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ctx.appBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      color: green,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Recommendation',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ctx.appText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: greenDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: ctx.appMutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class AiFoodNutritionResultBottomBar extends StatelessWidget {
  const AiFoodNutritionResultBottomBar({super.key, required this.controller});

  final AiFoodController controller;

  static const Color green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: context.appBackground,
        border: Border(
          top: BorderSide(
            color: context.appBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        final isSaving = controller.isSaving.value;
        final wasAdded = controller.wasAdded.value;
        final food = controller.nutrition.value;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                isSaving || wasAdded || food == null
                    ? null
                    : controller.confirmAndAddFoodToToday,
            icon:
                isSaving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Icon(
                      wasAdded
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
            label: Text(
              wasAdded
                  ? food != null && food.isPlainWaterOnly
                      ? 'Water Added Today'
                      : 'Added to Today'
                  : isSaving
                  ? 'Adding...'
                  : food != null &&
                      food.needsUserConfirmation &&
                      !controller.isUserConfirmed.value
                  ? food.isPlainWaterOnly
                      ? 'Confirm & Add Water'
                      : 'Confirm & Add to Today'
                  : food != null && food.isPlainWaterOnly
                  ? "Add to Today's Water"
                  : "Add to Today's Food",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: green,
              disabledBackgroundColor: green.withValues(alpha: 0.7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        );
      }),
    );
  }
}
