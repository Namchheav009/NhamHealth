import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../config/api_config.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
import '../../models/planner/ai_autofill_response_model.dart';
import '../../models/planner/meal_plan.dart';

String plannerImageUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('assets/') || trimmed.startsWith('package:')) {
    return trimmed;
  }
  var url = trimmed;
  // If backend returns localhost or 127.0.0.1, rewrite to ApiConfig.baseUrl
  if (url.startsWith('http://localhost:8080') ||
      url.startsWith('http://127.0.0.1:8080')) {
    url = url.replaceFirst(
      RegExp(r'http://(localhost|127\.0\.0\.1):8080'),
      ApiConfig.baseUrl,
    );
  }
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  return '${ApiConfig.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
}

String plannerMealName(PlannedMeal meal) => meal.name.tr;

class PlannerWeekDateStrip extends StatelessWidget {
  const PlannerWeekDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final normalizedSelected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final monday = normalizedSelected.subtract(
      Duration(days: normalizedSelected.weekday - DateTime.monday),
    );
    const weekdayKeys = [
      'planner.mon',
      'planner.tue',
      'planner.wed',
      'planner.thu',
      'planner.fri',
      'planner.sat',
      'planner.sun',
    ];

    final now = DateTime.now();
    return Row(
      children: List.generate(7, (index) {
        final date = DateTime(
          monday.year,
          monday.month,
          monday.day,
        ).add(Duration(days: index));
        final selected = DateUtils.isSameDay(date, selectedDate);
        final isToday = DateUtils.isSameDay(date, now);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 4),
            child: InkWell(
              key: ValueKey(
                'planner-week-date-${date.year}-${date.month}-${date.day}',
              ),
              onTap: () => onDateSelected(date),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? AppColors.primaryGreen
                          : context.appElevatedSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        selected
                            ? AppColors.primaryGreen
                            : (isToday
                                ? AppColors.primaryGreen.withValues(alpha: 0.5)
                                : context.appBorder),
                    width: isToday && !selected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isToday && !selected
                            ? 'planner.today'.tr
                            : weekdayKeys[index].tr,
                        maxLines: 1,
                        style: TextStyle(
                          color:
                              selected
                                  ? Colors.white
                                  : (isToday
                                      ? AppColors.primaryGreen
                                      : context.appText),
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('d').format(date),
                      style: TextStyle(
                        color: selected ? Colors.white : context.appText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? Colors.white
                                : (isToday
                                    ? AppColors.primaryGreen
                                    : Colors.transparent),
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
    );
  }
}

class PlannerSlotTheme {
  const PlannerSlotTheme({
    required this.accent,
    required this.soft,
    required this.icon,
  });

  final Color accent;
  final Color soft;
  final IconData icon;

  static PlannerSlotTheme of(MealPlanSlot slot) => switch (slot) {
    MealPlanSlot.breakfast => const PlannerSlotTheme(
      accent: Color(0xFFD97706),
      soft: Color(0xFFFEF3C7),
      icon: Icons.wb_sunny_rounded,
    ),
    MealPlanSlot.lunch => const PlannerSlotTheme(
      accent: Color(0xFF059669),
      soft: Color(0xFFDCFCE7),
      icon: Icons.restaurant_rounded,
    ),
    MealPlanSlot.dinner => const PlannerSlotTheme(
      accent: Color(0xFF7C3AED),
      soft: Color(0xFFEDE9FE),
      icon: Icons.nightlight_round,
    ),
    MealPlanSlot.snack => const PlannerSlotTheme(
      accent: Color(0xFFE11D48),
      soft: Color(0xFFFFE4E6),
      icon: Icons.apple_rounded,
    ),
  };
}

class PlannerMealImage extends StatelessWidget {
  const PlannerMealImage({
    super.key,
    required this.meal,
    this.width,
    this.height = 76,
    this.radius = 14,
    this.imageKey,
  });

  final PlannedMeal meal;
  final double? width;
  final double height;
  final double radius;
  final Key? imageKey;

  static const String fallbackMealAsset =
      'assets/images/meals/healthy_salad.jpg';

  Widget _buildFallback(PlannerSlotTheme theme, BuildContext context) {
    return Image.asset(
      fallbackMealAsset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder:
          (_, _, _) => Container(
            width: width,
            height: height,
            color:
                context.appIsDark
                    ? theme.soft.withValues(alpha: 0.15)
                    : theme.soft,
            child: Center(
              child: Icon(theme.icon, color: theme.accent, size: 26),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = meal.imageUrl.trim();
    final theme = PlannerSlotTheme.of(meal.slot);

    Widget imageWidget;
    if (rawUrl.isEmpty) {
      imageWidget = _buildFallback(theme, context);
    } else if (rawUrl.startsWith('assets/') || rawUrl.startsWith('package:')) {
      imageWidget = Image.asset(
        rawUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallback(theme, context),
      );
    } else {
      final url = plannerImageUrl(rawUrl);
      final refreshKey =
          Get.isRegistered<MealPlannerController>()
              ? Get.find<MealPlannerController>().imageRefreshKey.value
              : 0;
      imageWidget = CachedNetworkImage(
        key:
            imageKey ??
            ValueKey(
              '$url?id=${meal.id}&planId=${meal.planId ?? 0}&v=$refreshKey',
            ),
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder:
            (_, _) =>
                PageSkeleton.box(width: width, height: height, radius: radius),
        errorWidget: (_, _, _) => _buildFallback(theme, context),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: imageWidget),
    );
  }
}

class PlannerPageHeader extends StatelessWidget {
  const PlannerPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = true,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final titleContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: context.appText,
            fontSize: AppBackHeader.titleFontSize,
            fontWeight: AppBackHeader.titleFontWeight,
            height: 1.35,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ],
    );

    final actions =
        trailing == null && onClose == null
            ? null
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null) trailing!,
                if (trailing != null && onClose != null)
                  const SizedBox(width: 6),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: context.appText,
                    style: IconButton.styleFrom(
                      backgroundColor: context.appElevatedSurface,
                      shape: const CircleBorder(),
                    ),
                  ),
              ],
            );

    if (showBack) {
      return AppBackHeader(
        title: title,
        onBack: Get.back<void>,
        titleWidget: titleContent,
        trailing: actions,
      );
    }

    return SizedBox(
      height: AppBackButton.layoutSize,
      child: Row(
        children: [
          Expanded(child: titleContent),
          if (actions != null) ...[const SizedBox(width: 12), actions],
        ],
      ),
    );
  }
}

class PlannerPrimaryButton extends StatelessWidget {
  const PlannerPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    if (trailingIcon == null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.add_circle_outline_rounded, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.add_circle_outline_rounded, size: 20),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          Icon(trailingIcon, size: 20),
        ],
      ),
    );
  }
}

Future<void> showAutoFillConfirmDialog(
  BuildContext context,
  MealPlannerController controller,
) async {
  if (controller.isAutoFilling.value) return;
  var preferences = controller.dietaryPreferences.value;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (dialogContext) {
      return _AiAutoFillBottomSheet(
        controller: controller,
        initialFillEmptyOnly: true,
        initialPreferences: preferences,
        onPreferencesChanged: (p) => preferences = p,
      );
    },
  );

  if (confirmed != null) {
    var filled = 0;
    AiAutoFillPlanResponse? result;
    controller.autoFillStatusKey.value = 'planner.autofill_loading_preparing';
    controller.isAutoFilling.value = true;
    try {
      await controller.setDietaryPreferences(preferences);
      controller.autoFillStatusKey.value =
          'planner.autofill_loading_generating';
      filled = await controller.autoFillPlan(fillEmptyOnly: confirmed);
      result = controller.lastAiAutoFillResult.value;
      if (filled > 0) {
        controller.autoFillStatusKey.value =
            'planner.autofill_loading_refreshing';
        await controller.loadWeek(force: true);
        if (Get.isRegistered<WeightLossProjectionController>()) {
          try {
            await Get.find<WeightLossProjectionController>().loadForecast(
              forceRefresh: true,
            );
          } catch (_) {
            // The saved meal plan is still a success if forecast refresh fails.
          }
        }
      }
    } finally {
      controller.isAutoFilling.value = false;
    }
    if (filled > 0 && context.mounted) {
      await showAiAutoFillResultSheet(
        context,
        filledCount: filled,
        result: result,
      );
    }
  }
}

class _AiAutoFillBottomSheet extends StatefulWidget {
  const _AiAutoFillBottomSheet({
    required this.controller,
    required this.initialFillEmptyOnly,
    required this.initialPreferences,
    required this.onPreferencesChanged,
  });

  final MealPlannerController controller;
  final bool initialFillEmptyOnly;
  final MealPlannerDietaryPreferences initialPreferences;
  final ValueChanged<MealPlannerDietaryPreferences> onPreferencesChanged;

  @override
  State<_AiAutoFillBottomSheet> createState() => _AiAutoFillBottomSheetState();
}

class _AiAutoFillBottomSheetState extends State<_AiAutoFillBottomSheet> {
  late bool _fillEmptyOnly = widget.initialFillEmptyOnly;
  late MealPlannerDietaryPreferences _preferences = widget.initialPreferences;

  @override
  void initState() {
    super.initState();
    if (_emptySlotsCount == 0 && widget.controller.planMealCount > 0) {
      _fillEmptyOnly = false;
    }
  }

  int get _emptySlotsCount {
    int count = 0;
    for (final date in widget.controller.planDays) {
      final dayMeals = widget.controller.mealsFor(date);
      for (final slot in MealPlanSlot.values) {
        if (!dayMeals.any((m) => m.slot == slot)) count++;
      }
    }
    return count;
  }

  Future<void> _submit() async {
    if (_preferences.medicalFlags.contains('PREGNANT_OR_BREASTFEEDING')) {
      return;
    }
    if (!_fillEmptyOnly && widget.controller.planMealCount > 0) {
      final replace = await AppAlert.confirmAction(
        context: context,
        title: 'planner.autofill_replace_title',
        message: 'planner.autofill_replace_message',
        cancelText: 'common.cancel',
        confirmText: 'planner.autofill_replace_confirm',
        icon: Icons.autorenew_rounded,
        iconColor: AppColors.primaryGreen,
        confirmButtonColor: AppColors.primaryGreen,
      );
      if (replace != true || !mounted) return;
    }
    if (mounted) Navigator.of(context).pop(_fillEmptyOnly);
  }

  Widget _buildStrategyCard(
    BuildContext context, {
    required bool isSelected,
    required Color accentColor,
    required IconData icon,
    required String title,
    required String description,
    required String? badge,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? accentColor.withValues(alpha: 0.08)
                  : context.appSurfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? accentColor.withValues(alpha: 0.48)
                    : context.appBorder,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.appBorder, width: 1.5),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child:
                  isSelected
                      ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: accentColor),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isRecommended
                                    ? accentColor.withValues(alpha: 0.15)
                                    : context.appBorder.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color:
                                  isRecommended
                                      ? accentColor
                                      : context.appMutedText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.controller.healthGoal.value;
    final isPregnantOrBreastfeeding = _preferences.medicalFlags.contains(
      'PREGNANT_OR_BREASTFEEDING',
    );
    final hasPregnancyConflict =
        isPregnantOrBreastfeeding && goal == MealPlannerHealthGoal.loseWeight;
    final goalLabel = switch (goal) {
      MealPlannerHealthGoal.gainWeight => 'planner.goal_gain_weight'.tr,
      MealPlannerHealthGoal.maintainHealth => 'planner.goal_maintain_health'.tr,
      MealPlannerHealthGoal.loseWeight => 'planner.goal_lose_weight'.tr,
    };

    final accentColor =
        hasPregnancyConflict
            ? context.appOnWarningSurface
            : AppColors.primaryGreen;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: context.appBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'planner.ibm_smart_plan'.tr,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${'planner.current_goal'.tr}: $goalLabel',
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(null),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: context.appBorder.withValues(alpha: 0.5),
          ),

          // Scrollable content area
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pregnancy / Breastfeeding safety alert
                  if (hasPregnancyConflict) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.appWarningSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.health_and_safety_rounded,
                                color: context.appOnWarningSurface,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'planner.medical_review_required'.tr,
                                  style: TextStyle(
                                    color: context.appOnWarningSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'planner.pregnancy_weight_loss_warning'.tr,
                            style: TextStyle(
                              color: context.appOnWarningSurface,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Step 1: Choose how to fill
                  _AutoFillStepLabel(label: 'planner.autofill_step_mode_1'.tr),
                  const SizedBox(height: 8),

                  // Don't offer a no-op when every meal slot is already filled.
                  if (_emptySlotsCount > 0) ...[
                    _buildStrategyCard(
                      context,
                      isSelected: _fillEmptyOnly,
                      accentColor: accentColor,
                      icon: Icons.playlist_add_check_rounded,
                      title: 'planner.autofill_mode_empty_only'.tr,
                      description: 'planner.autofill_mode_empty_only_desc'.tr,
                      badge: 'planner.empty_slots_badge'.trParams({
                        'count': '$_emptySlotsCount',
                      }),
                      isRecommended: true,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _fillEmptyOnly = true);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Mode 2: Rebalance Entire Week
                  _buildStrategyCard(
                    context,
                    isSelected: !_fillEmptyOnly,
                    accentColor: accentColor,
                    icon: Icons.auto_mode_rounded,
                    title: 'planner.autofill_mode_rebalance'.tr,
                    description: 'planner.autofill_mode_rebalance_desc'.tr,
                    badge: null,
                    isRecommended: false,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _fillEmptyOnly = false);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Step 2: Food Preferences & Allergies
                  Material(
                    color: Colors.transparent,
                    child: _DietaryPreferencesEditor(
                      initialValue: _preferences,
                      onChanged: (value) {
                        setState(() => _preferences = value);
                        widget.onPreferencesChanged(value);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Medical disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appWarningSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          color: context.appOnWarningSurface,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'planner.medical_disclaimer'.tr,
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
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: context.appElevatedSurface,
              border: Border(
                top: BorderSide(
                  color: context.appBorder.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appText,
                        side: BorderSide(color: context.appBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'common.cancel'.tr,
                        style: TextStyle(
                          color: context.appText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: hasPregnancyConflict ? null : _submit,
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        hasPregnancyConflict
                            ? 'planner.autofill_unavailable'.tr
                            : 'planner.quick_auto_fill_btn'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: context.appOnBrand,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
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

class _DietaryPreferencesEditor extends StatefulWidget {
  const _DietaryPreferencesEditor({
    required this.initialValue,
    required this.onChanged,
  });

  final MealPlannerDietaryPreferences initialValue;
  final ValueChanged<MealPlannerDietaryPreferences> onChanged;

  @override
  State<_DietaryPreferencesEditor> createState() =>
      _DietaryPreferencesEditorState();
}

class _DietaryPreferencesEditorState extends State<_DietaryPreferencesEditor> {
  late MealPlannerDiet _diet;
  late Set<String> _allergens;
  late Set<String> _excludedIngredients;
  late Set<String> _medicalFlags;

  @override
  void initState() {
    super.initState();
    _diet = widget.initialValue.diet;
    _allergens = widget.initialValue.allergens.toSet();
    _excludedIngredients = widget.initialValue.excludedIngredients.toSet();
    _medicalFlags = widget.initialValue.medicalFlags.toSet();
  }

  void _emit() {
    widget.onChanged(
      MealPlannerDietaryPreferences(
        diet: _diet,
        allergens: _allergens.toList(growable: false),
        excludedIngredients: _excludedIngredients.toList(growable: false),
        medicalFlags: _medicalFlags.toList(growable: false),
      ),
    );
  }

  String _summaryText() {
    final list = <String>[];
    list.add(
      _diet == MealPlannerDiet.balanced
          ? 'planner.diet_balanced'.tr
          : (_diet == MealPlannerDiet.vegetarian
              ? 'planner.vegetarian'.tr
              : 'planner.diet_vegan'.tr),
    );
    final count = _allergens.length + _excludedIngredients.length;
    if (count > 0) {
      list.add(
        'planner.autofill_exclusions_count'.trParams({'count': '$count'}),
      );
    }
    if (_medicalFlags.isNotEmpty) {
      list.add(
        'planner.autofill_health_flags_count'.trParams({
          'count': '${_medicalFlags.length}',
        }),
      );
    }
    return list.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    const allergenOptions = <(String, String)>[
      ('peanut', 'planner.allergen_peanut'),
      ('milk', 'planner.allergen_milk'),
      ('egg', 'planner.allergen_egg'),
      ('wheat', 'planner.allergen_wheat'),
      ('fish', 'planner.allergen_fish'),
      ('shrimp', 'planner.allergen_shrimp'),
      ('soy', 'planner.allergen_soy'),
      ('tree nuts', 'planner.allergen_tree_nuts'),
      ('sesame', 'planner.allergen_sesame'),
    ];
    const avoidOptions = <(String, String)>[
      ('pork', 'planner.avoid_pork'),
      ('beef', 'planner.avoid_beef'),
      ('mushroom', 'planner.avoid_mushroom'),
      ('chili', 'planner.avoid_chili'),
    ];
    const medicalOptions = <(String, String)>[
      ('PREGNANT_OR_BREASTFEEDING', 'planner.medical_pregnancy'),
      ('DIABETES', 'planner.medical_diabetes'),
      ('HYPERTENSION', 'planner.medical_hypertension'),
    ];

    return Material(
      color: context.appSurfaceLow,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            initiallyExpanded: false,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primaryGreen,
                size: 18,
              ),
            ),
            title: Text(
              'planner.autofill_step_safety_2'.tr,
              style: TextStyle(
                color: context.appText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              _summaryText(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appMutedText, fontSize: 11),
            ),
            children: [
              DropdownButtonFormField<MealPlannerDiet>(
                initialValue: _diet,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'planner.diet_type'.tr,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: MealPlannerDiet.balanced,
                    child: Text(
                      'planner.diet_balanced'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: MealPlannerDiet.vegetarian,
                    child: Text(
                      'planner.vegetarian'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: MealPlannerDiet.vegan,
                    child: Text(
                      'planner.diet_vegan'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _diet = value);
                  _emit();
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'planner.allergens'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final option in allergenOptions)
                    FilterChip(
                      label: Text(option.$2.tr),
                      selected: _allergens.contains(option.$1),
                      onSelected: (selected) {
                        setState(
                          () =>
                              selected
                                  ? _allergens.add(option.$1)
                                  : _allergens.remove(option.$1),
                        );
                        _emit();
                      },
                    ),
                  for (final existing in _allergens.where(
                    (value) =>
                        !allergenOptions.any((option) => option.$1 == value),
                  ))
                    InputChip(
                      label: Text(existing),
                      onDeleted: () {
                        setState(() => _allergens.remove(existing));
                        _emit();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'planner.avoid_ingredients'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final option in avoidOptions)
                    FilterChip(
                      label: Text(option.$2.tr),
                      selected: _excludedIngredients.contains(option.$1),
                      onSelected: (selected) {
                        setState(
                          () =>
                              selected
                                  ? _excludedIngredients.add(option.$1)
                                  : _excludedIngredients.remove(option.$1),
                        );
                        _emit();
                      },
                    ),
                  for (final existing in _excludedIngredients.where(
                    (value) =>
                        !avoidOptions.any((option) => option.$1 == value),
                  ))
                    InputChip(
                      label: Text(existing),
                      onDeleted: () {
                        setState(() => _excludedIngredients.remove(existing));
                        _emit();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'planner.medical_considerations'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final option in medicalOptions)
                    FilterChip(
                      label: Text(option.$2.tr),
                      selected: _medicalFlags.contains(option.$1),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _medicalFlags.add(option.$1);
                          } else {
                            _medicalFlags.remove(option.$1);
                          }
                        });
                        _emit();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoFillStepLabel extends StatelessWidget {
  const _AutoFillStepLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Text(
      label,
      style: TextStyle(
        color: context.appText,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: .2,
      ),
    ),
  );
}

Future<void> showAiAutoFillResultSheet(
  BuildContext context, {
  required int filledCount,
  AiAutoFillPlanResponse? result,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: context.appSurfaceLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (sheetContext) => SingleChildScrollView(
          child: _AiAutoFillResultSheet(
            filledCount: filledCount,
            result: result,
          ),
        ),
  );
}

class _AiAutoFillResultSheet extends StatelessWidget {
  const _AiAutoFillResultSheet({required this.filledCount, this.result});

  final int filledCount;
  final AiAutoFillPlanResponse? result;

  @override
  Widget build(BuildContext context) {
    const accentColor = AppColors.primaryGreen;
    final planResult = result;
    final engineLabel =
        planResult == null
            ? 'planner.local_plan_ready'.tr
            : planResult.modelName == 'clinical-rule-fallback'
            ? 'planner.clinical_fallback'.tr
            : 'planner.smart_plan_ready'.tr;
    final normalizedGoal = planResult?.goal.trim().toUpperCase() ?? '';
    final isGain = normalizedGoal == 'GAIN_WEIGHT';
    final isLoss = normalizedGoal == 'LOSE_WEIGHT';
    final balance = planResult?.dailyDeficit ?? 0;
    final balanceLabel =
        isGain
            ? 'planner.daily_surplus'.tr
            : isLoss
            ? 'planner.daily_deficit'.tr
            : 'planner.daily_balance'.tr;
    final balanceValue =
        isGain
            ? balance < 0
                ? '+${balance.abs().round()} kcal'
                : '0 kcal'
            : isLoss
            ? balance > 0
                ? '−${balance.round()} kcal'
                : '0 kcal'
            : balance > 0
            ? '−${balance.round()} kcal'
            : balance < 0
            ? '+${balance.abs().round()} kcal'
            : '0 kcal';
    final projectionLabel =
        (isGain
                ? 'planner.days_gain'
                : isLoss
                ? 'planner.days_loss'
                : 'planner.days_change')
            .trParams({'count': '${planResult?.timeframeDays ?? 28}'});
    final projectionValue =
        isGain
            ? '+${planResult?.totalProjectedLossKg.toStringAsFixed(1) ?? '0.0'} kg'
            : isLoss
            ? '−${planResult?.totalProjectedLossKg.toStringAsFixed(1) ?? '0.0'} kg'
            : '0.0 kg';
    final goalLabel =
        isGain
            ? 'planner.goal_gain_weight'.tr
            : isLoss
            ? 'planner.goal_lose_weight'.tr
            : 'planner.goal_maintain_health'.tr;

    return Padding(
      key: const ValueKey('planner-autofill-success-sheet'),
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

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      engineLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'planner.autofill_success_title'.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'planner.auto_fill_success'.trParams({'count': '$filledCount'}),
            style: TextStyle(color: context.appMutedText, fontSize: 13),
          ),
          if (planResult != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: accentColor.withValues(alpha: 0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGain
                          ? Icons.trending_up_rounded
                          : isLoss
                          ? Icons.trending_down_rounded
                          : Icons.trending_flat_rounded,
                      size: 15,
                      color: accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'planner.aligned_with_goal'.trParams({'goal': goalLabel}),
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          if (planResult != null) ...[
            // Metric row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.appElevatedSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'planner.planned_intake'.tr,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${planResult.dailyPlannedCalories.round()} kcal',
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.appElevatedSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balanceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          balanceValue,
                          style: TextStyle(
                            color:
                                (isGain && balance < 0) ||
                                        (isLoss && balance > 0) ||
                                        (!isGain && !isLoss && balance.abs() <= 100)
                                    ? AppColors.primaryGreen
                                    : Colors.orange.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.appElevatedSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          projectionValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Rationale
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology_rounded, size: 18, color: accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      planResult.aiRationale,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.appBorder),
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text('common.done'.tr),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Get.toNamed(AppRoutes.mealPlannerWeightLossAnalysis);
              },
              icon: const Icon(Icons.insights_rounded, size: 18),
              label: Text(
                'planner.view_weight_loss_analysis'.tr,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showWeeklyReportDialog(
  BuildContext context,
  MealPlannerController controller,
) async {
  final pct = (controller.weeklyProgress * 100).round();
  final isComplete = controller.weeklyProgress >= 1.0;
  final totalSlots = controller.planDaysCount.value * 4;
  final plannedCount = controller.weeklyMealCount;
  final eatenCount = controller.weeklyEatenMeals;
  final goalLabel = switch (controller.healthGoal.value) {
    MealPlannerHealthGoal.gainWeight => 'planner.goal_gain_weight'.tr,
    MealPlannerHealthGoal.maintainHealth => 'planner.goal_maintain_health'.tr,
    MealPlannerHealthGoal.loseWeight => 'planner.goal_lose_weight'.tr,
  };
  final goalIcon = switch (controller.healthGoal.value) {
    MealPlannerHealthGoal.gainWeight => Icons.trending_up_rounded,
    MealPlannerHealthGoal.maintainHealth => Icons.trending_flat_rounded,
    MealPlannerHealthGoal.loseWeight => Icons.trending_down_rounded,
  };

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

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'planner.weekly_progress'.tr,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const SizedBox.expand(),
            ),
            SafeArea(
              minimum: const EdgeInsets.all(22),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(28, 29, 28, 28),
                      decoration: BoxDecoration(
                        color: dialogContext.appElevatedSurface,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: dialogContext.appElevatedSurface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              isComplete
                                  ? Icons.emoji_events_rounded
                                  : Icons.insights_rounded,
                              color: AppColors.primaryGreen,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
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
                                Icon(
                                  goalIcon,
                                  size: 13,
                                  color: Color(0xFF0F62FE),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  goalLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF0F62FE),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'planner.weekly_progress'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dialogContext.appText,
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isComplete
                                ? 'planner.all_meals_eaten'.tr
                                : 'planner.keep_going_on_track'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dialogContext.appMutedText,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: dialogContext.appSoftGreen,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'planner.meals_planned'.trParams({
                                        'count': '$plannedCount',
                                        'total': '$totalSlots',
                                      }),
                                      style: TextStyle(
                                        color: dialogContext.appText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      '$pct%',
                                      style: const TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: controller.weeklyProgress.clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    minHeight: 8,
                                    backgroundColor: dialogContext.appBorder,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                if (eatenCount > 0) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primaryGreen,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$eatenCount ${'planner.eaten'.tr.toLowerCase()}',
                                        style: const TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (avgCalories > 0) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      thickness: 0.8,
                                      color: dialogContext.appBorder.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'planner.weekly_nutrition_summary'.tr,
                                        style: TextStyle(
                                          color: dialogContext.appMutedText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'planner.day_calories_protein'
                                            .trParams({
                                              'cal': '$avgCalories',
                                              'pro': '$avgProtein',
                                            }),
                                        style: TextStyle(
                                          color: dialogContext.appText,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shadowColor: AppColors.primaryGreen.withValues(
                                  alpha: 0.38,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text('common.ok'.tr),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
