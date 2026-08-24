import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/profile/profile_controller.dart';

class InsightCard extends GetView<ProfileController> {
  const InsightCard({super.key});

  static const green = Color(0xFF009B46);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F8EE), Color(0xFFF5FFF7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD3EDDB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFBDEACD),
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: green,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're doing amazing!".tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.insight.value.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF65766C),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
