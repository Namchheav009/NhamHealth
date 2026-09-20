import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
        borderRadius: BorderRadius.circular(20),
        border: context.appIsDark ? Border.all(color: context.appBorder) : null,
        boxShadow: context.appHomeCardShadow,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(20),
        shadows: context.appIsDark ? context.appInnerShadow : const [],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(context),

              const SizedBox(height: 16),

              // Main / Primary Action
              _PrimaryQuickAction(
                key: const ValueKey('home-action-scan-food'),
                icon: Icons.document_scanner_rounded,
                color: AppColors.primaryGreen,
                title: 'home.action_scan_food'.tr,
                subtitle: 'home.action_scan_food_subtitle'.tr,
                onTap: () {
                  _lightImpact();
                  controller.openFoodAnalyzer();
                },
              ),

              const SizedBox(height: 12),

              // Secondary Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _SecondaryQuickAction(
                      key: const ValueKey('home-action-log-water'),
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF2196F3),
                      title: 'home.action_log_water'.tr,
                      subtitle: 'home.action_log_water_subtitle'.tr,
                      badgeText: '+1',
                      onTap: () {
                        _lightImpact();
                        controller.quickLogWater(1.0);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _SecondaryQuickAction(
                      key: const ValueKey('home-action-meal-plan'),
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFFFF8A00),
                      title: 'home.action_meal_plan'.tr,
                      subtitle: 'home.action_meal_plan_subtitle'.tr,
                      onTap: () {
                        _lightImpact();
                        controller.openMealPlanner();
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: AppColors.primaryGreen,
            size: 18,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.quick_actions'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'home.quick_actions_subtitle'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _lightImpact() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }
}

// =====================================================
// PRIMARY QUICK ACTION
// =====================================================

class _PrimaryQuickAction extends StatelessWidget {
  const _PrimaryQuickAction({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: context.appIsDark ? 0.13 : 0.07),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.18),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              // Main Icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 27),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SECONDARY QUICK ACTION
// =====================================================

class _SecondaryQuickAction extends StatelessWidget {
  const _SecondaryQuickAction({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    // FIX:
    // Ink doesn't support "constraints".
    // SizedBox controls the card height instead.
    return SizedBox(
      height: 120,
      child: Material(
        color: color.withValues(alpha: context.appIsDark ? 0.10 : 0.045),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: color.withValues(alpha: 0.18),
          highlightColor: color.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon row
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(icon, color: color, size: 21),
                        ),

                        // Badge
                        if (badgeText != null)
                          Positioned(
                            top: -5,
                            right: -7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.appElevatedSurface,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.25),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                badgeText!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    Icon(
                      Icons.arrow_outward_rounded,
                      color: context.appText.withValues(alpha: 0.30),
                      size: 17,
                    ),
                  ],
                ),

                const Spacer(),

                // Title
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtitle
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText.withValues(alpha: 0.50),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
