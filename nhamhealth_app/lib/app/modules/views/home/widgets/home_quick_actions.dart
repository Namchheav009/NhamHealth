import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';

class HomeQuickActions extends GetView<HomeController> {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: context.appIsDark ? Border.all(color: context.appBorder) : null,
        boxShadow: context.appHomeCardShadow,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(16),
        shadows: context.appIsDark ? context.appInnerShadow : const [],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 15,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'home.quick_actions'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _QuickActionTile(
                      key: const ValueKey('home-action-scan-food'),
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFF00A651),
                      label: 'home.action_scan_food'.tr,
                      onTap: () {
                        try {
                          HapticFeedback.lightImpact();
                        } catch (_) {}
                        controller.openFoodAnalyzer();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _QuickActionTile(
                      key: const ValueKey('home-action-log-water'),
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF0095FF),
                      label: 'home.action_log_water'.tr,
                      badgeText: '+1',
                      onTap: () => controller.quickLogWater(1.0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _QuickActionTile(
                      key: const ValueKey('home-action-meal-plan'),
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFFFF8A00),
                      label: 'home.action_meal_plan'.tr,
                      onTap: () {
                        try {
                          HapticFeedback.lightImpact();
                        } catch (_) {}
                        Get.toNamed<void>(AppRoutes.mealPlanner);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _QuickActionTile(
                      key: const ValueKey('home-action-explore-meals'),
                      icon: Icons.restaurant_menu_rounded,
                      color: const Color(0xFFFF5364),
                      label: 'home.action_explore_meals'.tr,
                      onTap: () {
                        try {
                          HapticFeedback.lightImpact();
                        } catch (_) {}
                        controller.openMeals();
                      },
                    ),
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: color.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: Center(child: Icon(icon, color: color, size: 23)),
                  ),
                  if (badgeText != null)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
