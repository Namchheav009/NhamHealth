import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/home/nutrition_progress_model.dart';

class NutritionProgressCard extends StatelessWidget {
  const NutritionProgressCard({
    super.key,
    required this.data,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final NutritionProgressModel data;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appElevatedSurface.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:
            context.appIsDark
                ? BorderSide(color: context.appBorder)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19, color: iconColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      data.title.trOrSelf,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.appMutedText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                '${data.value} / ${data.target}',
                maxLines: 1,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _buildSubtitle(),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        _isOverBudget ? FontWeight.w700 : FontWeight.w500,
                    color:
                        _isOverBudget
                            ? const Color(0xFFFF5252)
                            : context.appMutedText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.appColorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: data.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.appColorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isOverBudget {
    final isCalories =
        data.title.toLowerCase().contains('calorie') ||
        data.unit.toLowerCase() == 'kcal';
    if (!isCalories) return false;
    final current =
        int.tryParse(data.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final target =
        int.tryParse(data.target.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return target > 0 && current > target;
  }

  String _buildSubtitle() {
    final isCalories =
        data.title.toLowerCase().contains('calorie') ||
        data.unit.toLowerCase() == 'kcal';
    final isKm = Get.locale?.languageCode == 'km';
    if (isCalories) {
      final current =
          int.tryParse(data.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final target =
          int.tryParse(data.target.replaceAll(RegExp(r'[^0-9]'), '')) ?? 2000;
      final remaining = target - current;
      if (remaining >= 0) {
        return isKm ? 'សល់ $remaining kcal' : '$remaining left';
      } else {
        return isKm ? 'លើស ${-remaining} kcal' : '${-remaining} over';
      }
    }
    final pct = (data.progress * 100).toInt();
    return '${data.unit.trOrSelf} ($pct%)';
  }
}
