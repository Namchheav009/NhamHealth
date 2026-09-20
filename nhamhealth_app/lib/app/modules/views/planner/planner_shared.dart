import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/api_config.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/planner/meal_planner_controller.dart';
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
  final confirmed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'planner.auto_fill'.tr,
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
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primaryGreen,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'planner.auto_fill'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dialogContext.appText,
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'planner.auto_fill_confirm'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dialogContext.appMutedText,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed:
                                        () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: dialogContext.appBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(21),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: Text('common.cancel'.tr),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed:
                                        () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: AppColors.primaryGreen
                                          .withValues(alpha: 0.38),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(21),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: Text('planner.auto_fill'.tr),
                                  ),
                                ),
                              ),
                            ],
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

  if (confirmed == true) {
    await controller.autoFillPlan();
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
                          const SizedBox(height: 20),
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
                          const SizedBox(height: 20),
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
