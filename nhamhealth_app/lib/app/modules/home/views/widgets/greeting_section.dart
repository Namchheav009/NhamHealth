import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../controllers/home_controller.dart';
import 'inner_shadow.dart';
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
                    const Expanded(
                      child: Text(
                        'How are you feeling today?',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Obx(() {
                      final selected = controller.moods.firstWhereOrNull(
                        (mood) => mood.id == controller.selectedMoodId.value,
                      );
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child:
                            selected == null
                                ? const Text(
                                  'Select one',
                                  key: ValueKey('empty-mood'),
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 10,
                                  ),
                                )
                                : Container(
                                  key: ValueKey(selected.id),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.softGreen,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${selected.emoji} ${selected.name}',
                                    style: const TextStyle(
                                      color: AppColors.darkGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                      );
                    }),
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
                  return const SizedBox(
                    height: 78,
                    child: Center(
                      child: Text(
                        'No moods are available right now.',
                        style: TextStyle(
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
