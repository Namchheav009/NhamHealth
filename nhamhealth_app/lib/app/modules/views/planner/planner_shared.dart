import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/api_config.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_back_header.dart';
import '../../models/planner/meal_plan.dart';

String plannerImageUrl(String value) {
  if (value.isEmpty || value.startsWith('http')) return value;
  return '${ApiConfig.baseUrl}${value.startsWith('/') ? '' : '/'}$value';
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
      icon: Icons.wb_sunny_outlined,
    ),
    MealPlanSlot.lunch => const PlannerSlotTheme(
      accent: Color(0xFF059669),
      soft: Color(0xFFDCFCE7),
      icon: Icons.restaurant_rounded,
    ),
    MealPlanSlot.dinner => const PlannerSlotTheme(
      accent: Color(0xFF7C3AED),
      soft: Color(0xFFEDE9FE),
      icon: Icons.nights_stay_outlined,
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
  });

  final PlannedMeal meal;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = plannerImageUrl(meal.imageUrl);
    final theme = PlannerSlotTheme.of(meal.slot);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child:
            url.isEmpty
                ? Container(
                  color:
                      context.appIsDark
                          ? theme.soft.withValues(alpha: 0.15)
                          : theme.soft,
                  child: Center(
                    child: Icon(theme.icon, color: theme.accent, size: 26),
                  ),
                )
                : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, _) => Container(
                        color:
                            context.appIsDark
                                ? theme.soft.withValues(alpha: 0.12)
                                : theme.soft,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.accent,
                          ),
                        ),
                      ),
                  errorWidget:
                      (_, _, _) => Container(
                        color:
                            context.appIsDark
                                ? theme.soft.withValues(alpha: 0.15)
                                : theme.soft,
                        child: Center(
                          child: Icon(
                            theme.icon,
                            color: theme.accent,
                            size: 26,
                          ),
                        ),
                      ),
                ),
      ),
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
          if (actions != null) ...[
            const SizedBox(width: 12),
            actions,
          ],
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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon ?? Icons.add_circle_outline_rounded, size: 20),
    label: Text(label),
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    ),
  );
}
