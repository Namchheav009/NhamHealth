import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/calories_controller.dart';
import '../../../../theme/app_colors.dart';

class CalorieIntakeEditor extends GetView<CaloriesController> {
  const CalorieIntakeEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit intake'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? context.appText : const Color(0xFF555555),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _roundButton(
                context: context,
                icon: Icons.remove_rounded,
                onTap: controller.decreaseCalories,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? context.appColorScheme.surfaceContainerHigh
                            : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isDark ? context.appBorder : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: TextField(
                    controller: controller.intakeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: controller.updateCaloriesFromInput,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Text(
                'kcal'.tr,
                style: TextStyle(
                  color: isDark ? context.appMutedText : Colors.black38,
                  fontSize: 10,
                ),
              ),

              const SizedBox(width: 6),

              _roundButton(
                context: context,
                icon: Icons.add_rounded,
                onTap: controller.increaseCalories,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _quickAdd(context, '+100', () => controller.addCalories(100)),

              const SizedBox(width: 8),

              _quickAdd(context, '+250', () => controller.addCalories(250)),

              const SizedBox(width: 8),

              _quickAdd(context, '+500', () => controller.addCalories(500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 50,
        height: 42,
        decoration: BoxDecoration(
          color:
              context.appIsDark
                  ? Color.alphaBlend(
                    const Color(0xFFFF641E).withValues(alpha: 0.11),
                    context.appSurfaceLow,
                  )
                  : const Color(0xFFFFF4EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFBE9D)),
        ),
        child: Icon(icon, color: const Color(0xFFFF641E)),
      ),
    );
  }

  Widget _quickAdd(BuildContext context, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color:
              context.appIsDark
                  ? Color.alphaBlend(
                    const Color(0xFFFF6B35).withValues(alpha: 0.10),
                    context.appSurfaceLow,
                  )
                  : const Color(0xFFFFF2EC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFC9AE)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFF6B35),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = context.appIsDark;
    return BoxDecoration(
      color: isDark ? context.appSurfaceLow : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: isDark ? Border.all(color: context.appBorder) : null,
      boxShadow:
          isDark
              ? context.appCardShadow
              : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
    );
  }
}
