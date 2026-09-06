import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';
import 'mood_card.dart';

class GreetingSection extends GetView<HomeController> {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(15),
        border: context.appIsDark ? Border.all(color: context.appBorder) : null,
        boxShadow: context.appHomeCardShadow,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(15),
        shadows: context.appIsDark ? context.appInnerShadow : const [],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'How are you feeling today?'.tr,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                final moods = controller.moods;
                final validationPulse = controller.moodValidationPulse.value;
                final moodMissing = controller.selectedMoodId.value == null;
                if (controller.isMoodsLoading.value && moods.isEmpty) {
                  return const SizedBox(
                    height: 78,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (moods.isEmpty) {
                  return SizedBox(
                    height: 78,
                    child: Center(
                      child: Text(
                        'No moods are available right now.'.tr,
                        style: TextStyle(color: context.appText, fontSize: 12),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  key: ValueKey('mood-validation-$validationPulse'),
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    itemCount: moods.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final mood = moods[index];
                      return MoodCard(
                        emoji: mood.emoji,
                        label: mood.name,
                        selected: controller.selectedMoodId.value == mood.id,
                        invalid: moodMissing && validationPulse > 0,
                        validationPulse: validationPulse,
                        onTap: () => controller.selectMood(mood.id),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
