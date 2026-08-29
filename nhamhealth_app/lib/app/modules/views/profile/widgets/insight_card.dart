import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/profile/profile_controller.dart';
import '../../../../theme/app_colors.dart';

class InsightCard extends GetView<ProfileController> {
  const InsightCard({super.key});

  static const green = Color(0xFF009B46);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.appSoftGreen, context.appElevatedSurface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.appColorScheme.primaryContainer,
              borderRadius: const BorderRadius.all(Radius.circular(15)),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.insight.value.tr,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appMutedText,
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
