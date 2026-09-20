import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized nutrient icons and colors across NhamHealth.
/// Aligned with the Daily Wellness standard.
abstract class AppNutrientTheme {
  AppNutrientTheme._();

  // Canonical Icons
  static const IconData caloriesIcon = Icons.local_fire_department_rounded;
  static const IconData proteinIcon = Icons.bolt_rounded;
  static const IconData carbsIcon = Icons.grain_rounded;
  static const IconData fatIcon = Icons.opacity_rounded;
  static const IconData waterIcon = Icons.water_drop_rounded;
  static const IconData fiberIcon = Icons.air_rounded;
  static const IconData sugarIcon = Icons.hexagon_rounded;

  // Canonical Colors
  static const Color caloriesColor = Color(0xFFFF641E);
  static const Color proteinColor = AppColors.primaryGreen; // 0xFF00A651
  static const Color carbsColor = Color(0xFFF59E0B);
  static const Color fatColor = Color(0xFFF43F5E);
  static const Color waterColor = Color(0xFF4FC3F7);
  static const Color fiberColor = Color(0xFF9747FF);
  static const Color sugarColor = Color(0xFFFF5CB8);

  // Soft Tint Backgrounds
  static const Color caloriesBg = Color(0xFFFFF1E8);
  static const Color proteinBg = Color(0xFFEAF7EC);
  static const Color carbsBg = Color(0xFFFFF7E6);
  static const Color fatBg = Color(0xFFFFECEE);
  static const Color waterBg = Color(0xFFE8F7FF);
  static const Color fiberBg = Color(0xFFF2EAFE);
  static const Color sugarBg = Color(0xFFFFEDF7);

  /// Resolves the canonical icon for a given nutrient name or key.
  static IconData iconFor(String nutrient) {
    final lower = nutrient.toLowerCase().trim();
    if (lower.contains('calor') || lower.contains('kcal')) return caloriesIcon;
    if (lower.contains('protein')) return proteinIcon;
    if (lower.contains('carb')) return carbsIcon;
    if (lower.contains('fat')) return fatIcon;
    if (lower.contains('water') || lower.contains('hydrat')) return waterIcon;
    if (lower.contains('fiber')) return fiberIcon;
    if (lower.contains('sugar')) return sugarIcon;
    return Icons.eco_rounded;
  }

  /// Resolves the canonical color for a given nutrient name or key.
  static Color colorFor(String nutrient) {
    final lower = nutrient.toLowerCase().trim();
    if (lower.contains('calor') || lower.contains('kcal')) return caloriesColor;
    if (lower.contains('protein')) return proteinColor;
    if (lower.contains('carb')) return carbsColor;
    if (lower.contains('fat')) return fatColor;
    if (lower.contains('water') || lower.contains('hydrat')) return waterColor;
    if (lower.contains('fiber')) return fiberColor;
    if (lower.contains('sugar')) return sugarColor;
    return AppColors.primaryGreen;
  }

  /// Resolves the canonical soft background for a given nutrient name or key.
  static Color backgroundFor(String nutrient) {
    final lower = nutrient.toLowerCase().trim();
    if (lower.contains('calor') || lower.contains('kcal')) return caloriesBg;
    if (lower.contains('protein')) return proteinBg;
    if (lower.contains('carb')) return carbsBg;
    if (lower.contains('fat')) return fatBg;
    if (lower.contains('water') || lower.contains('hydrat')) return waterBg;
    if (lower.contains('fiber')) return fiberBg;
    if (lower.contains('sugar')) return sugarBg;
    return AppColors.softGreen;
  }
}
