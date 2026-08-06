import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import 'mood_card.dart';

class GreetingSection extends GetView<HomeController> {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Text(
              'How are you feeling today?',
              style: TextStyle(
                color: Color(0xFF00A651),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 75,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              physics:
                  const BouncingScrollPhysics(),
              itemCount: controller.moods.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final mood =
                    controller.moods[index];

                return Obx(
                  () => MoodCard(
                    emoji: mood.emoji,
                    label: mood.label,
                    selected:
                        controller
                            .selectedMoodIndex
                            .value ==
                        index,
                    onTap: () =>
                        controller.selectMood(
                          index,
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}