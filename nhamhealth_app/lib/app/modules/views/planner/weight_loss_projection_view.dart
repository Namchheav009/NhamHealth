import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
import '../../models/planner/meal_plan.dart';
import '../../models/planner/weight_loss_forecast_model.dart';
import 'planner_shared.dart';

class WeightLossProjectionView extends GetView<WeightLossProjectionController> {
  const WeightLossProjectionView({
    super.key,
    this.embedded = false,
  });

  final bool embedded;
  String get _pageTitle => 'planner.weight_loss_forecast'.tr;

  Color _positiveText(BuildContext context) =>
      context.appIsDark ? const Color(0xFF72DDA7) : AppColors.darkGreen;

  Color _secondaryAccent(BuildContext context) =>
      context.appIsDark ? const Color(0xFF78DCD0) : const Color(0xFF087F72);

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Obx(() => _forecastContent(context, embedded: true));
    }
    return Scaffold(
      backgroundColor: context.appBackground,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontalFor(context),
                  8,
                  AppSpacing.pageHorizontalFor(context),
                  0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: AppBackHeader(
                    title: _pageTitle,
                    onBack: () => Get.back(),
                  ),
                ),
              ),
              Expanded(child: Obx(() => _forecastContent(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _forecastContent(BuildContext context, {bool embedded = false}) {
    if (controller.isLoading.value && controller.forecast.value == null) {
      return const PageSkeleton.plannerSlots();
    }

    final forecast = controller.forecast.value;
    if (forecast == null) {
      return Padding(
        key: embedded ? const ValueKey('embedded-weight-loss-forecast') : null,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _pageTitle,
              style: TextStyle(
                color: context.appText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: context.appMutedText,
            ),
            const SizedBox(height: 10),
            Text(
              'planner.forecast_unavailable'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appMutedText, fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => controller.loadForecast(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('planner.retry'.tr),
            ),
          ],
        ),
      );
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (embedded) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  _pageTitle,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!forecast.hasPlannedMeals)
          _emptyForecastCard(context)
        else ...[
          _projectionHeroCard(context, forecast),
          const SizedBox(height: 16),
          _energyBalanceCard(context, forecast),
          const SizedBox(height: 22),
          _recommendationsSection(context, forecast),
        ],
      ],
    );

    if (embedded) {
      return KeyedSubtree(
        key: const ValueKey('embedded-weight-loss-forecast'),
        child: content,
      );
    }
    return RefreshIndicator(
      onRefresh: () => controller.loadForecast(forceRefresh: true),
      color: AppColors.primaryGreen,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontalFor(context),
          14,
          AppSpacing.pageHorizontalFor(context),
          28,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyForecastCard(BuildContext context) => Container(
    key: const ValueKey('forecast-needs-meals'),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.appBorder),
    ),
    child: Column(
      children: [
        Icon(
          Icons.restaurant_menu_rounded,
          size: 34,
          color: AppColors.primaryGreen,
        ),
        const SizedBox(height: 10),
        Text(
          'planner.forecast_needs_meals_title'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'planner.forecast_needs_meals_help'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appMutedText, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _projectionHeroCard(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    final isSurplus = forecast.isSurplus;
    final lossText =
        isSurplus
            ? '+0.0 kg'
            : '−${forecast.projectedWeightLossKg.toStringAsFixed(1)} kg';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.appSoftGreen, context.appElevatedSurface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.20),
        ),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isSurplus
                          ? AppColors.accentOrange
                          : AppColors.primaryGreen)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSurplus
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 20,
                  color:
                      isSurplus
                          ? AppColors.accentOrange
                          : AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'planner.forecast_hero_title'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _paceBadge(context, forecast),
            ],
          ),
          const SizedBox(height: 16),

          // Big projected weight loss number
          Center(
            child: Column(
              children: [
                Text(
                  lossText,
                  style: TextStyle(
                    color:
                        isSurplus
                            ? context.appOnWarningSurface
                            : _positiveText(context),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'planner.timeframe_days'.trParams({
                    'count': '${forecast.timeframeDays}',
                  }),
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Starting -> Target Weight Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.appSurfaceLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'planner.current_weight'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${forecast.currentWeightKg.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: context.appMutedText,
                  size: 18,
                ),
                Column(
                  children: [
                    Text(
                      'planner.projected_weight'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${forecast.projectedEndWeightKg.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color:
                            isSurplus
                                ? context.appText
                                : _positiveText(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Timeframe Selection Chips
          Row(
            children: [
              Text(
                'planner.timeframe'.tr,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children:
                        WeightLossProjectionController.availableTimeframes.map((
                          days,
                        ) {
                          final isSelected =
                              controller.selectedTimeframeDays.value == days;
                          final label =
                              days < 14
                                  ? 'planner.timeframe_days'.trParams({
                                    'count': '$days',
                                  })
                                  : 'planner.timeframe_weeks'.trParams({
                                    'count': '${days ~/ 7}',
                                  });

                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: InkWell(
                              key: ValueKey('timeframe-chip-$days'),
                              onTap: () => controller.setTimeframeDays(days),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.primaryGreen
                                          : context.appSurfaceLow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primaryGreen
                                            : context.appBorder.withValues(
                                              alpha: 0.5,
                                            ),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? context.appOnBrand
                                            : context.appText,
                                    fontSize: 12,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _paceBadge(BuildContext context, WeightLossForecast forecast) {
    Color badgeColor;
    String label;

    switch (forecast.paceStatus.toUpperCase()) {
      case 'BALANCED':
        badgeColor = _positiveText(context);
        label = 'planner.pace_balanced'.tr;
        break;
      case 'BELOW_TARGET':
        badgeColor = _secondaryAccent(context);
        label = 'planner.pace_below_target'.tr;
        break;
      case 'ABOVE_TARGET':
        badgeColor = context.appOnWarningSurface;
        label = 'planner.pace_above_target'.tr;
        break;
      case 'SURPLUS':
        badgeColor = context.appOnWarningSurface;
        label = 'planner.pace_surplus'.tr;
        break;
      case 'STEADY':
        badgeColor = _secondaryAccent(context);
        label = 'planner.pace_steady'.tr;
        break;
      case 'OPTIMAL':
        badgeColor = _positiveText(context);
        label = 'planner.pace_optimal'.tr;
        break;
      case 'RAPID':
      default:
        badgeColor = context.appOnWarningSurface;
        label = 'planner.pace_rapid'.tr;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _energyBalanceCard(BuildContext context, WeightLossForecast forecast) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'planner.daily_deficit'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${forecast.dailyDeficitCalories.round()} ${'planner.kcal_per_day'.tr}',
                style: TextStyle(
                  color:
                      forecast.isSurplus
                          ? context.appOnWarningSurface
                          : _positiveText(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Comparison row: TDEE vs Planned
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  context,
                  title: 'planner.tdee_burn'.tr,
                  value: '${forecast.tdeeCalories.round()} kcal',
                  subtext:
                      '${'planner.bmr_baseline'.tr}: ${forecast.bmrCalories.round()}',
                  icon: Icons.bolt_rounded,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  context,
                  title: 'planner.planned_intake'.tr,
                  value: '${forecast.dailyPlannedCalories.round()} kcal',
                  subtext:
                      '${forecast.weeklyPaceKg.toStringAsFixed(2)} ${'planner.kg_per_week'.tr}',
                  icon: Icons.restaurant_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          if (forecast.calorieWarning) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appWarningSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.appOnWarningSurface.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: context.appOnWarningSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'planner.safe_floor_alert'.tr,
                          style: TextStyle(
                            color: context.appOnWarningSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          forecast.calorieWarningMessage,
                          style: TextStyle(
                            color: context.appOnWarningSurface.withValues(
                              alpha: 0.85,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricBox(
    BuildContext context, {
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: context.appText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
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
    );
  }

  Widget _recommendationsSection(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'planner.weight_loss_recommendations'.tr,
          style: TextStyle(
            color: context.appText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'planner.weight_loss_recommendations_help'.tr,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),

        // Segmented Tabs: Suitable Foods vs Healthy Beverages
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.appSurfaceLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _tabButton(
                  context,
                  key: const ValueKey('tab-suitable-foods'),
                  label: 'planner.tab_suitable_foods'.tr,
                  icon: Icons.restaurant_menu_rounded,
                  isSelected: controller.selectedTab.value == 0,
                  onTap: () => controller.setSelectedTab(0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _tabButton(
                  context,
                  key: const ValueKey('tab-healthy-beverages'),
                  label: 'planner.tab_healthy_beverages'.tr,
                  icon: Icons.local_drink_rounded,
                  isSelected: controller.selectedTab.value == 1,
                  onTap: () => controller.setSelectedTab(1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Recommendation cards list
        Builder(
          builder: (context) {
            final isFoods = controller.selectedTab.value == 0;
            final rawItems =
                isFoods
                    ? forecast.recommendedFoods
                    : forecast.recommendedBeverages;

            // Guarantee zero duplicates by name and source ID
            final seenNames = <String>{};
            final seenIds = <int>{};
            final items = <ForecastRecommendationItem>[];
            for (final item in rawItems) {
              final norm = item.name.trim().toLowerCase();
              if (seenNames.contains(norm)) {
                continue;
              }
              if (item.sourceId > 0 && seenIds.contains(item.sourceId)) {
                continue;
              }
              seenNames.add(norm);
              if (item.sourceId > 0) seenIds.add(item.sourceId);
              items.add(item);
              if (items.length == 2) break;
            }

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'planner.no_recommendations_found'.tr,
                    style: TextStyle(color: context.appMutedText, fontSize: 13),
                  ),
                ),
              );
            }

            return Column(
              children:
                  items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _recommendationCard(context, item),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _tabButton(
    BuildContext context, {
    Key? key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? context.appElevatedSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? context.appTileShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primaryGreen : context.appMutedText,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? context.appText : context.appMutedText,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(
    BuildContext context,
    ForecastRecommendationItem item,
  ) {
    final imageUri = plannerImageUrl(item.imageUrl);
    final source = _extractSource(item.rationale);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Compact Image / Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      imageUri.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: imageUri,
                            fit: BoxFit.cover,
                            placeholder:
                                (_, _) => Container(
                                  color: context.appSurfaceLow,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (_, _, _) => _fallbackThumb(context, item),
                          )
                          : _fallbackThumb(context, item),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Rationale & Nutrients
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '${item.calories.round()} kcal',
                          style: TextStyle(
                            color: _positiveText(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.proteinGrams > 0) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${item.proteinGrams.toStringAsFixed(0)}g pro',
                            style: TextStyle(
                              color: _secondaryAccent(context),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // "Add to Plan" button
              ElevatedButton(
                key: ValueKey('add-recommendation-${item.sourceId}'),
                onPressed: () => _showAddToPlanSheet(context, item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 34),
                ),
                child: Text(
                  'planner.add_to_plan'.tr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final isBeverage = item.isBeverage;
              final analysisTitle =
                  isBeverage
                      ? 'planner.analysis_drink_loss'.tr
                      : 'planner.analysis_food_loss'.tr;
              final analysisIcon =
                  isBeverage
                      ? Icons.water_drop_outlined
                      : Icons.fitness_center_rounded;
              final analysisColor =
                  isBeverage
                      ? _secondaryAccent(context)
                      : _positiveText(context);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: analysisColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: analysisColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(analysisIcon, size: 14, color: analysisColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            analysisTitle,
                            style: TextStyle(
                              color: analysisColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (source != null) _sourceBadge(context, source),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.rationale,
                      style: TextStyle(
                        color: context.appText.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String? _extractSource(String rationale) {
    if (rationale.contains('BBC Good Food')) return 'BBC Good Food';
    if (rationale.contains('EatingWell')) return 'EatingWell';
    if (rationale.contains('Healthline')) return 'Healthline';
    return null;
  }

  Widget _sourceBadge(BuildContext context, String source) {
    final accent = _secondaryAccent(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: accent.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        source,
        style: TextStyle(
          color: accent,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _fallbackThumb(BuildContext context, ForecastRecommendationItem item) {
    return Container(
      color: (item.isBeverage
              ? _secondaryAccent(context)
              : AppColors.primaryGreen)
          .withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          item.isBeverage
              ? Icons.local_drink_rounded
              : Icons.restaurant_rounded,
          size: 28,
          color:
              item.isBeverage
                  ? _secondaryAccent(context)
                  : AppColors.primaryGreen,
        ),
      ),
    );
  }

  /// Interactive Bottom Sheet to pick day, meal slot, and add the recommended item directly to plan
  Future<void> _showAddToPlanSheet(
    BuildContext context,
    ForecastRecommendationItem item,
  ) async {
    final plannerCtrl =
        Get.isRegistered<MealPlannerController>()
            ? Get.find<MealPlannerController>()
            : null;

    final planDays =
        plannerCtrl != null && plannerCtrl.planDays.isNotEmpty
            ? plannerCtrl.planDays
            : List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

    DateTime selectedDate = planDays.first;
    MealPlanSlot selectedSlot =
        item.isBeverage ? MealPlanSlot.snack : MealPlanSlot.lunch;
    double servings = 1.0;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.appSurfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.appBorder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'planner.add_to_plan'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. Day selector
                    Text(
                      'planner.select_day'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            planDays.map((d) {
                              final isSelected =
                                  d.year == selectedDate.year &&
                                  d.month == selectedDate.month &&
                                  d.day == selectedDate.day;
                              final dayLabel = DateFormat(
                                'EEE, MMM d',
                              ).format(d);

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(dayLabel),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setSheetState(() => selectedDate = d);
                                    }
                                  },
                                  selectedColor: AppColors.primaryGreen,
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : context.appText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Meal Slot selector
                    Text(
                      'planner.select_meal_slot'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children:
                          MealPlanSlot.values.map((slot) {
                            final isSelected = selectedSlot == slot;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: ChoiceChip(
                                  label: Text(
                                    slot.name.capitalizeFirst ?? slot.name,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : context.appText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setSheetState(() => selectedSlot = slot);
                                    }
                                  },
                                  selectedColor: AppColors.primaryGreen,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Servings Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'planner.servings'.tr,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  servings > 0.5
                                      ? () =>
                                          setSheetState(() => servings -= 0.5)
                                      : null,
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                              color: AppColors.primaryGreen,
                            ),
                            Text(
                              servings.toStringAsFixed(1),
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  servings < 5.0
                                      ? () =>
                                          setSheetState(() => servings += 0.5)
                                      : null,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 4. Confirm Button
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await controller.addRecommendationToPlan(
                          context: context,
                          item: item,
                          targetDate: selectedDate,
                          slot: selectedSlot,
                          servings: servings,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'planner.confirm_add'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
