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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors:
              context.appIsDark
                  ? [context.appSoftGreen, context.appElevatedSurface]
                  : [const Color(0xFFF5FBF3), const Color(0xFFFFFCE2)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: .7)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  context.appIsDark ? context.appSelectedSurface : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    context.appIsDark
                        ? context.appColorScheme.outlineVariant
                        : const Color(0xFFDCEEE0),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x263C6B4A),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: context.appIsDark ? context.appColorScheme.primary : green,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're doing amazing!".tr,
                  style: TextStyle(
                    fontSize: 16,
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
