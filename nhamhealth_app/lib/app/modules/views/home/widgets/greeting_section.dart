import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';
import 'mood_card.dart';

class GreetingSection extends GetView<HomeController> {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: AppShadows.surface,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(15),
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
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 78,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: moods.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final mood = moods[index];
                      return MoodCard(
                        emoji: mood.emoji,
                        label: mood.name,
                        selected: controller.selectedMoodId.value == mood.id,
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
