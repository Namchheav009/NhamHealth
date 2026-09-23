import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/home/home_controller.dart';
import 'mood_card.dart';

class GreetingSection extends GetView<HomeController> {
  const GreetingSection({super.key});

  String get _moodSubtitle {
    const key = 'home.slide_to_choose_your_mood';
    final translated = key.tr;
    if (translated != key) return translated;
    return Get.locale?.languageCode == 'km'
        ? 'អូសដើម្បីជ្រើសរើសអារម្មណ៍របស់អ្នក'
        : 'Slide to choose your mood';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'home.how_are_you_feeling_today'.tr,
        style: TextStyle(
          color: context.appText,
          fontSize: 18,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        _moodSubtitle,
        style: TextStyle(
          color: context.appMutedText,
          fontSize: 12,
          height: 1.25,
        ),
      ),
      const SizedBox(height: 9),
      Obx(() {
        final moods = controller.moods;
        final validationPulse = controller.moodValidationPulse.value;
        final moodMissing = controller.selectedMoodId.value == null;
        if (controller.isMoodsLoading.value && moods.isEmpty) {
          return const SizedBox(
            height: 78,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (moods.isEmpty) {
          return SizedBox(
            height: 78,
            child: Center(
              child: Text(
                'home.no_moods_are_available_right_now'.tr,
                style: TextStyle(color: context.appText, fontSize: 12),
              ),
            ),
          );
        }
        return SizedBox(
          key: ValueKey('mood-validation-$validationPulse'),
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: moods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
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
  );
}
